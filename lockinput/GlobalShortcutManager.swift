//
//  GlobalShortcutManager.swift
//  lockinput
//

import AppKit
import Carbon
import Combine
import ApplicationServices

struct KeyboardShortcut: Equatable {
    let keyCode: UInt32
    let modifiers: UInt32
    let keyDisplay: String

    var usesFlagsChangedMonitor: Bool {
        Self.modifierMask(for: keyCode) != 0
    }

    var isCapsLockOnly: Bool {
        keyCode == 57 && modifiers == 0
    }

    var requiredModifiers: UInt32 {
        modifiers | Self.modifierMask(for: keyCode)
    }

    var displayText: String {
        var parts: [String] = []
        for (mask, name) in Self.modifierNames where modifiers & mask != 0 {
            parts.append(name)
        }
        parts.append(keyDisplay)
        return parts.joined(separator: " + ")
    }

    static let functionModifier = UInt32(kEventKeyModifierFnMask)
    private static let modifierNames: [(UInt32, String)] = [
        (UInt32(cmdKey), "Command"), (UInt32(controlKey), "Control"),
        (UInt32(optionKey), "Option"), (UInt32(shiftKey), "Shift"),
        (functionModifier, "Globe")
    ]

    static func modifierMask(for keyCode: UInt32) -> UInt32 {
        switch keyCode {
        case 54, 55: return UInt32(cmdKey)
        case 56, 60: return UInt32(shiftKey)
        case 58, 61: return UInt32(optionKey)
        case 59, 62: return UInt32(controlKey)
        case 63: return functionModifier
        case 57: return UInt32(alphaLock)
        default: return 0
        }
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        if flags.contains(.control) { result |= UInt32(controlKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }
        if flags.contains(.function) { result |= functionModifier }
        return result
    }
}

final class GlobalShortcutManager: ObservableObject {
    static let shared = GlobalShortcutManager()

    private enum DefaultsKey {
        static let keyCode = "temporaryABCShortcutKeyCode"
        static let modifiers = "temporaryABCShortcutModifiers"
        static let keyDisplay = "temporaryABCShortcutKeyDisplay"
    }

    private static let hotKeySignature: OSType = 0x4C494E50
    private let hotKeyID = EventHotKeyID(signature: GlobalShortcutManager.hotKeySignature, id: 1)

    @Published private(set) var shortcut: KeyboardShortcut?
    @Published private(set) var needsAccessibilityPermission = false

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var modifierGlobalMonitor: Any?
    private var modifierLocalMonitor: Any?
    private var isModifierShortcutPressed = false
    private var lastCapsLockShortcutAt = Date.distantPast
    private var isModifierShortcutCancelled = false
    private var usesKeyEventMonitor = false
    private(set) var isRecording = false

    private init() {
        shortcut = Self.loadShortcut()
    }

    deinit {
        unregisterShortcut()
        stopModifierMonitors()
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    func start() {
        installEventHandlerIfNeeded()
        registerStoredShortcut()
    }

    @discardableResult
    func updateShortcut(from event: NSEvent) -> Bool {
        guard let shortcut = KeyboardShortcut(event: event) else { return false }
        updateShortcut(shortcut)
        return true
    }

    func updateShortcut(_ shortcut: KeyboardShortcut) {
        self.shortcut = shortcut
        UserDefaults.standard.set(Int(shortcut.keyCode), forKey: DefaultsKey.keyCode)
        UserDefaults.standard.set(Int(shortcut.modifiers), forKey: DefaultsKey.modifiers)
        UserDefaults.standard.set(shortcut.keyDisplay, forKey: DefaultsKey.keyDisplay)
        registerStoredShortcut()
    }

    func setRecording(_ recording: Bool) {
        guard isRecording != recording else { return }
        isRecording = recording
        isModifierShortcutPressed = false
        isModifierShortcutCancelled = false
        registerStoredShortcut()
    }

    func refreshMonitoringPermission() {
        let needsPermission = (shortcut?.usesFlagsChangedMonitor == true || usesKeyEventMonitor)
            && !AXIsProcessTrusted()
        let permissionGranted = needsAccessibilityPermission && !needsPermission
        needsAccessibilityPermission = needsPermission
        if permissionGranted {
            let useKeyEvents = usesKeyEventMonitor
            stopModifierMonitors()
            usesKeyEventMonitor = useKeyEvents
            startModifierMonitors()
        }
    }

    func requestMonitoringPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        refreshMonitoringPermission()
    }

    func clearShortcut() {
        shortcut = nil
        UserDefaults.standard.removeObject(forKey: DefaultsKey.keyCode)
        UserDefaults.standard.removeObject(forKey: DefaultsKey.modifiers)
        UserDefaults.standard.removeObject(forKey: DefaultsKey.keyDisplay)
        unregisterShortcut()
        stopModifierMonitors()
    }

    func handleHotKeyPressed() {
        guard !isRecording else { return }
        InputMethodManager.shared.switchTemporarilyToSelectedInputSource()
    }

    private static func loadShortcut() -> KeyboardShortcut? {
        guard UserDefaults.standard.object(forKey: DefaultsKey.keyCode) != nil,
              UserDefaults.standard.object(forKey: DefaultsKey.modifiers) != nil,
              let keyDisplay = UserDefaults.standard.string(forKey: DefaultsKey.keyDisplay),
              !keyDisplay.isEmpty else {
            return nil
        }

        let keyCode = UInt32(UserDefaults.standard.integer(forKey: DefaultsKey.keyCode))
        let modifiers = UInt32(UserDefaults.standard.integer(forKey: DefaultsKey.modifiers))
        return KeyboardShortcut(keyCode: keyCode, modifiers: modifiers, keyDisplay: keyDisplay)
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandlerRef == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                guard let event else { return OSStatus(eventNotHandledErr) }

                var eventHotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &eventHotKeyID
                )

                guard status == noErr,
                      eventHotKeyID.signature == GlobalShortcutManager.hotKeySignature,
                      eventHotKeyID.id == 1 else {
                    return OSStatus(eventNotHandledErr)
                }

                DispatchQueue.main.async {
                    GlobalShortcutManager.shared.handleHotKeyPressed()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )
    }

    private func registerStoredShortcut() {
        unregisterShortcut()
        stopModifierMonitors()
        guard !isRecording, let shortcut else { return }

        if shortcut.usesFlagsChangedMonitor {
            startModifierMonitors()
            return
        }

        var newHotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &newHotKeyRef
        )

        if status == noErr {
            hotKeyRef = newHotKeyRef
        } else {
            // Observe combinations Carbon cannot reserve, including system shortcuts.
            usesKeyEventMonitor = true
            startModifierMonitors()
        }
    }

    private func unregisterShortcut() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func startModifierMonitors() {
        guard modifierGlobalMonitor == nil, modifierLocalMonitor == nil else { return }

        refreshMonitoringPermission()
        modifierGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { [weak self] event in
            DispatchQueue.main.async {
                self?.handleModifierFlagsChanged(event)
            }
        }

        modifierLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { [weak self] event in
            self?.handleModifierFlagsChanged(event)
            return event
        }
    }

    private func stopModifierMonitors() {
        if let modifierGlobalMonitor {
            NSEvent.removeMonitor(modifierGlobalMonitor)
            self.modifierGlobalMonitor = nil
        }

        if let modifierLocalMonitor {
            NSEvent.removeMonitor(modifierLocalMonitor)
            self.modifierLocalMonitor = nil
        }

        isModifierShortcutPressed = false
        isModifierShortcutCancelled = false
        usesKeyEventMonitor = false
        needsAccessibilityPermission = false
    }

    private func handleModifierFlagsChanged(_ event: NSEvent) {
        guard !isRecording, let shortcut else { return }
        let modifiers = KeyboardShortcut.carbonModifiers(from: event.modifierFlags)

        if usesKeyEventMonitor {
            if event.type == .keyDown, !event.isARepeat,
               UInt32(event.keyCode) == shortcut.keyCode, modifiers == shortcut.modifiers {
                handleHotKeyPressed()
            }
            return
        }

        guard shortcut.usesFlagsChangedMonitor else { return }
        if event.type == .keyDown {
            // Holding a modifier to type another shortcut is not a modifier-only press.
            if modifiers != 0 {
                isModifierShortcutCancelled = true
            }
            return
        }

        if shortcut.keyCode == 57 {
            if event.keyCode == 57, modifiers == shortcut.modifiers {
                triggerCapsLockShortcutIfNeeded()
            }
            return
        }

        let required = shortcut.requiredModifiers
        if modifiers == required {
            isModifierShortcutPressed = true
        } else if modifiers & ~required != 0 {
            isModifierShortcutCancelled = true
        }

        // Fire once after the entire chord is released, not on its first modifier.
        if modifiers == 0 {
            if isModifierShortcutPressed, !isModifierShortcutCancelled {
                handleHotKeyPressed()
            }
            isModifierShortcutPressed = false
            isModifierShortcutCancelled = false
        }
    }

    private func triggerCapsLockShortcutIfNeeded() {
        let now = Date()
        guard now.timeIntervalSince(lastCapsLockShortcutAt) > 0.2 else { return }

        lastCapsLockShortcutAt = now
        handleHotKeyPressed()
    }
}

extension KeyboardShortcut {
    init?(event: NSEvent) {
        let keyCode = UInt32(event.keyCode)
        let modifiers = Self.carbonModifiers(from: event.modifierFlags)
        if event.type == .flagsChanged {
            let ownModifier = Self.modifierMask(for: keyCode)
            guard ownModifier != 0 else { return nil }
            // Caps Lock sends a change for both toggles; other modifiers must be down.
            guard keyCode == 57 || modifiers & ownModifier != 0 else { return nil }
            self.keyCode = keyCode
            self.modifiers = modifiers & ~ownModifier
            switch keyCode {
            case 54, 55: self.keyDisplay = "Command"
            case 56, 60: self.keyDisplay = "Shift"
            case 58, 61: self.keyDisplay = "Option"
            case 59, 62: self.keyDisplay = "Control"
            case 63: self.keyDisplay = "Globe"
            default: self.keyDisplay = "Caps Lock"
            }
        } else {
            guard event.type == .keyDown, !event.isARepeat else { return nil }
            self.keyCode = keyCode
            self.modifiers = modifiers
            self.keyDisplay = Self.keyDisplay(from: event)
        }
    }

    private static func keyDisplay(from event: NSEvent) -> String {
        let names: [UInt16: String] = [
            36: "Return", 48: "Tab", 49: "Space", 51: "Delete", 53: "Escape",
            64: "F17", 65: "Keypad .", 67: "Keypad *", 69: "Keypad +",
            71: "Clear", 75: "Keypad /", 76: "Keypad Enter", 78: "Keypad -",
            79: "F18", 80: "F19", 81: "Keypad =", 82: "Keypad 0",
            83: "Keypad 1", 84: "Keypad 2", 85: "Keypad 3", 86: "Keypad 4",
            87: "Keypad 5", 88: "Keypad 6", 89: "Keypad 7", 90: "F20",
            91: "Keypad 8", 92: "Keypad 9", 96: "F5", 97: "F6", 98: "F7",
            99: "F3", 100: "F8", 101: "F9", 103: "F11", 105: "F13",
            106: "F16", 107: "F14", 109: "F10", 111: "F12", 113: "F15",
            114: "Help", 115: "Home", 116: "Page Up", 117: "Forward Delete",
            118: "F4", 119: "End", 120: "F2", 121: "Page Down", 122: "F1",
            123: "Left", 124: "Right", 125: "Down", 126: "Up"
        ]
        if let name = names[event.keyCode] { return name }
        let characters = (event.charactersIgnoringModifiers ?? "").uppercased()
        return characters.isEmpty ? "Key \(event.keyCode)" : characters
    }
}
