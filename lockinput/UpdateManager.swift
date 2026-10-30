import AppKit
import Combine
import CryptoKit
import Foundation

@MainActor
final class UpdateManager: ObservableObject {
    struct Release: Decodable {
        struct Asset: Decodable {
            let name: String
            let browser_download_url: URL
            let digest: String?
        }

        let tag_name: String
        let draft: Bool
        let prerelease: Bool
        let assets: [Asset]

        var version: String {
            tag_name.hasPrefix("v") ? String(tag_name.dropFirst()) : tag_name
        }
    }

    static let shared = UpdateManager()
    static let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    @Published private(set) var isBusy = false
    @Published private(set) var statusKey: String?
    @Published private(set) var availableRelease: Release?

    func checkForUpdates() async {
        guard !isBusy else { return }
        isBusy = true
        statusKey = "updates.checking"
        availableRelease = nil
        defer { isBusy = false }

        do {
            var request = URLRequest(url: URL(string: "https://api.github.com/repos/trah01/keepinput/releases/latest")!)
            request.timeoutInterval = 20
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("keepinput/\(Self.currentVersion)", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            if (response as? HTTPURLResponse)?.statusCode == 404 {
                statusKey = "updates.noRelease"
                return
            }
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw UpdateFailure.invalidRelease
            }
            let release = try JSONDecoder().decode(Release.self, from: data)
            guard !release.draft, !release.prerelease, Self.isValidVersion(release.version) else {
                throw UpdateFailure.invalidRelease
            }
            if UpdateVersion.normalized(release.version)
                .compare(UpdateVersion.normalized(Self.currentVersion), options: .numeric) == .orderedDescending {
                availableRelease = release
                statusKey = "updates.available"
            } else {
                statusKey = "updates.upToDate"
            }
        } catch {
            statusKey = "updates.checkFailed"
        }
    }

    func installUpdate() async {
        guard !isBusy, let release = availableRelease else { return }
        guard let asset = release.assets.first(where: {
            $0.name.lowercased().hasSuffix(".dmg") && $0.browser_download_url.scheme == "https"
                && $0.browser_download_url.host == "github.com"
                && $0.browser_download_url.path.hasPrefix("/trah01/keepinput/releases/download/")
        }) else {
            statusKey = "updates.noInstaller"
            return
        }

        isBusy = true
        statusKey = "updates.installing"
        defer { isBusy = false }
        do {
            let appURL = Bundle.main.bundleURL
            guard !appURL.path.contains("/AppTranslocation/"),
                  !appURL.path.hasPrefix("/Volumes/"),
                  FileManager.default.isWritableFile(atPath: appURL.deletingLastPathComponent().path) else {
                statusKey = "updates.moveToApplications"
                return
            }
            var request = URLRequest(url: asset.browser_download_url)
            request.timeoutInterval = 120
            let (download, response) = try await URLSession.shared.download(for: request)
            defer { try? FileManager.default.removeItem(at: download) }
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw UpdateFailure.invalidRelease
            }
            let bundleID = Bundle.main.bundleIdentifier ?? "com.cloudwings.lockinput"
            let expectedVersion = release.version
            let expectedDigest = asset.digest
            try await Task.detached {
                try UpdateInstaller.prepareAndLaunch(download: download, digest: expectedDigest,
                                                     appURL: appURL, bundleID: bundleID,
                                                     version: expectedVersion)
            }.value
            NSApp.terminate(nil)
        } catch {
            statusKey = "updates.installFailed"
        }
    }

    private static func isValidVersion(_ version: String) -> Bool {
        version.range(of: #"^[0-9]+(\.[0-9]+)*$"#, options: .regularExpression) != nil
    }
}

private enum UpdateFailure: Error {
    case invalidRelease
    case invalidInstaller
}

private enum UpdateVersion {
    nonisolated static func normalized(_ version: String) -> String {
        var components = version.split(separator: ".").map { String(Int($0) ?? 0) }
        while components.count > 1 && components.last == "0" {
            components.removeLast()
        }
        return components.joined(separator: ".")
    }
}

private enum UpdateInstaller {
    nonisolated static func prepareAndLaunch(download: URL, digest: String?, appURL: URL,
                                 bundleID: String, version: String) throws {
        let files = FileManager.default
        if let digest {
            let data = try Data(contentsOf: download, options: .mappedIfSafe)
            let actual = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            guard digest.lowercased() == "sha256:\(actual)" else {
                throw UpdateFailure.invalidInstaller
            }
        }

        let temporary = files.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try files.createDirectory(at: temporary, withIntermediateDirectories: true)
        defer { try? files.removeItem(at: temporary) }
        let image = temporary.appendingPathComponent("update.dmg")
        try files.copyItem(at: download, to: image)
        let mount = temporary.appendingPathComponent("mount", isDirectory: true)
        try run("/usr/bin/hdiutil", ["attach", image.path, "-readonly", "-nobrowse", "-mountpoint", mount.path])
        defer { try? run("/usr/bin/hdiutil", ["detach", mount.path]) }

        let candidates = try files.contentsOfDirectory(at: mount, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "app" }
        guard let source = candidates.first(where: { Bundle(url: $0)?.bundleIdentifier == bundleID }),
              let bundle = Bundle(url: source),
              let bundledVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              UpdateVersion.normalized(bundledVersion) == UpdateVersion.normalized(version),
              let executable = bundle.executableURL,
              files.isExecutableFile(atPath: executable.path) else {
            throw UpdateFailure.invalidInstaller
        }

        // Stage on the same volume so replacement and rollback use atomic renames.
        let stage = appURL.deletingLastPathComponent()
            .appendingPathComponent(".keepinput-update-\(UUID().uuidString)", isDirectory: true)
        try files.createDirectory(at: stage, withIntermediateDirectories: false)
        var helperStarted = false
        defer { if !helperStarted { try? files.removeItem(at: stage) } }
        let replacement = stage.appendingPathComponent("new.app")
        try run("/usr/bin/ditto", [source.path, replacement.path])

        // Paths are positional arguments, never interpolated into shell commands.
        let script = """
        parent_pid="$1"
        app_path="$2"
        stage_path="$3"
        attempts=0
        while /bin/kill -0 "$parent_pid" 2>/dev/null; do
            attempts=$((attempts + 1))
            if [ "$attempts" -ge 60 ]; then exit 1; fi
            /bin/sleep 1
        done
        if /bin/mv "$app_path" "$stage_path/old.app"; then
            if /bin/mv "$stage_path/new.app" "$app_path"; then
                if /usr/bin/open "$app_path"; then
                    /bin/rm -rf "$stage_path"
                    exit 0
                fi
                /bin/mv "$app_path" "$stage_path/new.app"
            fi
            /bin/mv "$stage_path/old.app" "$app_path"
        fi
        /usr/bin/open "$app_path"
        """
        let helper = Process()
        helper.executableURL = URL(fileURLWithPath: "/bin/sh")
        helper.arguments = ["-c", script, "keepinput-update", String(ProcessInfo.processInfo.processIdentifier), appURL.path, stage.path]
        helper.standardInput = FileHandle.nullDevice
        helper.standardOutput = FileHandle.nullDevice
        helper.standardError = FileHandle.nullDevice
        try helper.run()
        helperStarted = true
    }

    private nonisolated static func run(_ executable: String, _ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw UpdateFailure.invalidInstaller }
    }
}
