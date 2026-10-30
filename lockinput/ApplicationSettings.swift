import AppKit
import Combine
import ServiceManagement

final class MenuBarIconManager: ObservableObject {
    static let shared = MenuBarIconManager()
    private static let defaultsKey = "hideMenuBarIcon"
    @Published private(set) var isHidden: Bool

    private init() {
        isHidden = UserDefaults.standard.bool(forKey: Self.defaultsKey)
    }

    func setHidden(_ hidden: Bool) {
        isHidden = hidden
        UserDefaults.standard.set(hidden, forKey: Self.defaultsKey)
    }
}

final class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()
    @Published private(set) var isEnabled = false
    @Published private(set) var requiresApproval = false
    @Published private(set) var isUpdating = false
    @Published private(set) var hasError = false

    var isSupported: Bool {
        if #available(macOS 13.0, *) { return true }
        return false
    }

    var messageKey: String? {
        if !isSupported { return "settings.loginUnsupported" }
        if hasError { return "settings.loginFailed" }
        if requiresApproval { return "settings.loginApprovalRequired" }
        return nil
    }

    private init() {
        refresh()
    }

    func refresh(clearError: Bool = true) {
        if clearError { hasError = false }
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            isEnabled = status == .enabled
            requiresApproval = status == .requiresApproval
        } else {
            isEnabled = false
            requiresApproval = false
        }
    }

    func setEnabled(_ enabled: Bool) {
        guard !isUpdating, isSupported else { return }
        isUpdating = true
        hasError = false
        defer {
            // The switch always reflects the service, including after a failed change.
            refresh(clearError: false)
            if isEnabled != enabled && !requiresApproval {
                hasError = true
            }
            isUpdating = false
        }
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                hasError = true
            }
        }
    }

    func openLoginItemsSettings() {
        if #available(macOS 13.0, *) {
            SMAppService.openSystemSettingsLoginItems()
        }
    }
}
