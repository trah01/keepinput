//
//  SettingsView.swift
//  lockinput
//

import SwiftUI
import AppKit

private enum SettingsTypography {
    static let primary = Font.system(size: 14)
    static let control = Font.system(size: 13)
    static let secondary = Font.system(size: 12)
    static let section = Font.system(size: 12, weight: .bold)
}

struct SettingsView: View {
    @ObservedObject var inputManager = InputMethodManager.shared
    @ObservedObject var languageManager = LanguageManager.shared
    @ObservedObject var shortcutManager = GlobalShortcutManager.shared
    @ObservedObject var updateManager = UpdateManager.shared
    @ObservedObject var menuBarIconManager = MenuBarIconManager.shared
    @ObservedObject var launchAtLoginManager = LaunchAtLoginManager.shared
    @State private var showingUpdateConfirmation = false
    @AppStorage("restorePreviousLockState") var restorePreviousLockState = false
    @AppStorage("temporaryInputSourceID") var temporaryInputSourceID = ""
    @AppStorage("temporaryInputRestoreInterval") var temporaryInputRestoreInterval = 5.0
    @State private var isRecordingShortcut = false
    @State private var pendingModifierShortcut: KeyboardShortcut?
    @State private var shortcutRecordingMonitors: [Any] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // General section
                VStack(alignment: .leading, spacing: 6) {
                    Text("settings.section.general".localized(with: languageManager))
                        .font(SettingsTypography.section)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)

                    settingsSection {
                        SettingsRow(iconName: "globe", title: "settings.language".localized(with: languageManager)) {
                            Picker("", selection: $languageManager.currentLanguage) {
                                ForEach(AppLanguage.allCases) { language in
                                    Text(language.displayName).tag(language)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .fixedSize()
                            .frame(width: 140, alignment: .trailing)
                        }

                        Divider()

                        SettingsRow(iconName: "power", title: "settings.launchAtLogin".localized(with: languageManager)) {
                            Toggle("", isOn: Binding(
                                get: { launchAtLoginManager.isEnabled },
                                set: { launchAtLoginManager.setEnabled($0) }
                            ))
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .accessibilityLabel("settings.launchAtLogin".localized(with: languageManager))
                                .disabled(!launchAtLoginManager.isSupported || launchAtLoginManager.isUpdating)
                        }

                        if let messageKey = launchAtLoginManager.messageKey {
                            Text(messageKey.localized(with: languageManager))
                                .font(SettingsTypography.secondary)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if launchAtLoginManager.requiresApproval {
                            Button("settings.openLoginItems".localized(with: languageManager)) {
                                launchAtLoginManager.openLoginItemsSettings()
                            }
                        }

                        Divider()

                        SettingsRow(iconName: "menubar.rectangle", title: "settings.hideMenuBarIcon".localized(with: languageManager)) {
                            Toggle("", isOn: Binding(
                                get: { menuBarIconManager.isHidden },
                                set: { menuBarIconManager.setHidden($0) }
                            ))
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .accessibilityLabel("settings.hideMenuBarIcon".localized(with: languageManager))
                        }

                        Divider()

                        SettingsRow(iconName: "arrow.clockwise", title: "settings.restorePreviousLockState".localized(with: languageManager)) {
                            Toggle("", isOn: $restorePreviousLockState)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                    }
                }

                // Shortcut & Temporary Switch section
                VStack(alignment: .leading, spacing: 6) {
                    Text("settings.section.shortcut".localized(with: languageManager))
                        .font(SettingsTypography.section)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)

                    settingsSection {
                        SettingsRow(iconName: "keyboard", title: "settings.temporaryInputShortcut".localized(with: languageManager)) {
                            HStack(spacing: 8) {
                                Button(action: {
                                    if isRecordingShortcut {
                                        stopShortcutRecording()
                                    } else {
                                        startShortcutRecording()
                                    }
                                }) {
                                    Text(shortcutButtonTitle)
                                        .font(SettingsTypography.control)
                                        .lineLimit(1)
                                        .frame(width: 110, alignment: .leading)
                                }
                                .buttonStyle(.bordered)
                                .help(shortcutButtonTitle)

                                Button(action: {
                                    shortcutManager.clearShortcut()
                                    stopShortcutRecording()
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .semibold))
                                        .frame(width: 20, height: 20)
                                }
                                .buttonStyle(.bordered)
                                .disabled(shortcutManager.shortcut == nil && !isRecordingShortcut)
                                .help("settings.clearShortcut".localized(with: languageManager))
                            }
                        }

                        if isRecordingShortcut {
                            Text("settings.shortcutRecordingHint".localized(with: languageManager))
                                .font(SettingsTypography.secondary)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if shortcutManager.needsAccessibilityPermission {
                            Text("settings.shortcutPermissionHint".localized(with: languageManager))
                                .font(SettingsTypography.secondary)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Button("settings.shortcutGrantPermission".localized(with: languageManager)) {
                                shortcutManager.requestMonitoringPermission()
                            }
                        }

                        Divider()

                        SettingsRow(iconName: "arrow.right.circle", title: "settings.temporaryInputSource".localized(with: languageManager)) {
                            Picker("", selection: $temporaryInputSourceID) {
                                Text("settings.temporaryInputSourceAutomatic".localized(with: languageManager))
                                    .tag("")

                                ForEach(inputManager.availableInputSources, id: \.self) { source in
                                    Text(inputManager.getInputSourceName(source))
                                        .tag(inputManager.getInputSourceID(source))
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .fixedSize()
                            .frame(width: 170, alignment: .trailing)
                        }

                        Divider()

                        SettingsRow(iconName: "timer", title: "settings.temporaryInputRestoreInterval".localized(with: languageManager)) {
                            Stepper(value: $temporaryInputRestoreInterval, in: 1...60, step: 1) {
                                Text(String(format: "settings.secondsFormat".localized(with: languageManager), Int(temporaryInputRestoreInterval)))
                                    .font(SettingsTypography.control)
                            }
                        }

                        Divider()

                        Text(String(format: "settings.temporaryInputHint".localized(with: languageManager), Int(temporaryInputRestoreInterval)))
                            .font(SettingsTypography.secondary)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 4)
                    }
                }

                // About section
                VStack(alignment: .leading, spacing: 6) {
                    Text("settings.section.about".localized(with: languageManager))
                        .font(SettingsTypography.section)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)

                    settingsSection {
                        SettingsRow(iconName: "arrow.down.circle", title: "updates.version".localized(with: languageManager)) {
                            HStack(spacing: 8) {
                                Text(UpdateManager.currentVersion)
                                    .font(SettingsTypography.control)
                                    .foregroundColor(.secondary)
                                if updateManager.isBusy {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                Button((updateManager.availableRelease == nil ? "updates.check" : "updates.install")
                                    .localized(with: languageManager)) {
                                    if updateManager.availableRelease != nil {
                                        showingUpdateConfirmation = true
                                    } else {
                                        Task {
                                            await updateManager.checkForUpdates()
                                            showingUpdateConfirmation = updateManager.availableRelease != nil
                                        }
                                    }
                                }
                                .disabled(updateManager.isBusy)
                            }
                        }

                        if let statusKey = updateManager.statusKey {
                            Text(statusKey == "updates.available"
                                 ? String(format: statusKey.localized(with: languageManager), updateManager.availableRelease?.version ?? "")
                                 : statusKey.localized(with: languageManager))
                                .font(SettingsTypography.secondary)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityAddTraits(.updatesFrequently)
                        }

                        Divider()

                        SettingsRow(iconName: "info.circle", title: "settings.about".localized(with: languageManager)) {
                            Link(destination: URL(string: "https://github.com/trah01/keepinput")!) {
                                Text("settings.projectLink".localized(with: languageManager))
                                    .font(SettingsTypography.control)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .frame(width: 460, height: 500)
        .onAppear {
            launchAtLoginManager.refresh()
            shortcutManager.refreshMonitoringPermission()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            launchAtLoginManager.refresh()
            shortcutManager.refreshMonitoringPermission()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)) { _ in
            stopShortcutRecording()
        }
        .onDisappear {
            stopShortcutRecording()
        }
        .alert("updates.confirmTitle".localized(with: languageManager), isPresented: $showingUpdateConfirmation) {
            Button("updates.install".localized(with: languageManager)) {
                Task { await updateManager.installUpdate() }
            }
            Button("updates.cancel".localized(with: languageManager), role: .cancel) { }
        } message: {
            Text(String(format: "updates.confirmMessage".localized(with: languageManager),
                        updateManager.availableRelease?.version ?? ""))
        }
    }

    var shortcutButtonTitle: String {
        if isRecordingShortcut {
            return pendingModifierShortcut?.displayText
                ?? "settings.recordingShortcut".localized(with: languageManager)
        }

        return shortcutManager.shortcut?.displayText
            ?? "settings.setShortcut".localized(with: languageManager)
    }

    func settingsSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 0.5)
        )
    }

    func startShortcutRecording() {
        stopShortcutRecording()
        isRecordingShortcut = true
        shortcutManager.setRecording(true)

        let keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if shortcutManager.updateShortcut(from: event) {
                stopShortcutRecording()
            }
            return nil
        }

        let flagsChangedMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            if let candidate = KeyboardShortcut(event: event) {
                pendingModifierShortcut = candidate
                if candidate.keyCode == 57 {
                    shortcutManager.updateShortcut(candidate)
                    stopShortcutRecording()
                }
            } else if KeyboardShortcut.carbonModifiers(from: event.modifierFlags) == 0,
                      let pendingModifierShortcut {
                shortcutManager.updateShortcut(pendingModifierShortcut)
                stopShortcutRecording()
            }
            return nil
        }

        shortcutRecordingMonitors = [keyDownMonitor, flagsChangedMonitor].compactMap { $0 }
    }

    func stopShortcutRecording() {
        for monitor in shortcutRecordingMonitors {
            NSEvent.removeMonitor(monitor)
        }
        shortcutRecordingMonitors.removeAll()
        pendingModifierShortcut = nil
        isRecordingShortcut = false
        shortcutManager.setRecording(false)
    }
}

struct SettingsRowIcon: View {
    let name: String
    
    var body: some View {
        Image(systemName: name)
            .font(.system(size: 11, weight: .semibold))
            .symbolRenderingMode(.monochrome)
            .foregroundColor(.secondary)
            .frame(width: 22, height: 22)
            .accessibilityHidden(true)
    }
}

struct SettingsRow<Content: View>: View {
    let iconName: String
    let title: String
    @ViewBuilder let control: () -> Content
    
    var body: some View {
        HStack(spacing: 12) {
            SettingsRowIcon(name: iconName)
            
            Text(title)
                .font(SettingsTypography.primary)
                .foregroundColor(.primary)
            
            Spacer()
            
            control()
                .font(SettingsTypography.control)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.vertical, 4)
    }
}

#if DEBUG && canImport(PreviewsMacros)
#Preview {
    SettingsView()
}
#endif
