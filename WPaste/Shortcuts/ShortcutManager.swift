import Carbon.HIToolbox
import Foundation
import Observation

@MainActor
protocol ShortcutRegistering: AnyObject {
    func register(_ shortcut: Shortcut, action: ShortcutAction) -> Bool
    func unregister(_ shortcut: Shortcut)
}

@MainActor
@Observable
final class ShortcutManager {
    static let defaultShortcuts: [ShortcutAction: Shortcut] = [
        .showHistory: .init(keyCode: 9, modifiers: [.command, .shift]),
        .showPasteStack: .init(keyCode: 8, modifiers: [.command, .shift]),
        .nextPinboard: .init(keyCode: 124, modifiers: [.command]),
        .previousPinboard: .init(keyCode: 123, modifiers: [.command]),
        .quickPaste: .init(keyCode: 18, modifiers: [.command]),
        .plainTextMode: .init(keyCode: 56, modifiers: [.shift])
    ]

    private(set) var shortcuts: [ShortcutAction: Shortcut]
    private let registrar: ShortcutRegistering

    init(registrar: ShortcutRegistering = CarbonShortcutRegistrar()) {
        self.registrar = registrar
        shortcuts = Self.defaultShortcuts
        for (action, shortcut) in shortcuts {
            _ = registrar.register(shortcut, action: action)
        }
    }

    func update(_ action: ShortcutAction, to shortcut: Shortcut) -> ShortcutUpdateResult {
        if let conflict = shortcuts.first(where: { $0.key != action && $0.value == shortcut })?.key {
            return .internalConflict(conflict)
        }
        guard registrar.register(shortcut, action: action) else { return .registrationFailed }
        if let old = shortcuts[action] { registrar.unregister(old) }
        shortcuts[action] = shortcut
        return .success
    }

    func resetDefaults() {
        shortcuts.values.forEach(registrar.unregister)
        shortcuts = Self.defaultShortcuts
        for (action, shortcut) in shortcuts { _ = registrar.register(shortcut, action: action) }
    }
}

@MainActor
final class CarbonShortcutRegistrar: ShortcutRegistering {
    private var references: [Shortcut: EventHotKeyRef] = [:]

    func register(_ shortcut: Shortcut, action: ShortcutAction) -> Bool {
        var reference: EventHotKeyRef?
        let identifier = EventHotKeyID(
            signature: OSType(0x5750_5354),
            id: UInt32(ShortcutAction.allCases.firstIndex(of: action) ?? 0) + 1
        )
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers.carbonFlags,
            identifier,
            GetApplicationEventTarget(),
            0,
            &reference
        )
        guard status == noErr, let reference else { return false }
        references[shortcut] = reference
        return true
    }

    func unregister(_ shortcut: Shortcut) {
        guard let reference = references.removeValue(forKey: shortcut) else { return }
        UnregisterEventHotKey(reference)
    }
}

private extension ShortcutModifiers {
    var carbonFlags: UInt32 {
        var flags: UInt32 = 0
        if contains(.command) { flags |= UInt32(cmdKey) }
        if contains(.option) { flags |= UInt32(optionKey) }
        if contains(.control) { flags |= UInt32(controlKey) }
        if contains(.shift) { flags |= UInt32(shiftKey) }
        return flags
    }
}

