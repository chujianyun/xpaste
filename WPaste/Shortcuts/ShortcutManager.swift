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
        .nextPinboard: .init(keyCode: 124, modifiers: [.command]),
        .previousPinboard: .init(keyCode: 123, modifiers: [.command]),
        .quickPaste: .init(keyCode: 18, modifiers: [.command]),
        .plainTextMode: .init(keyCode: 56, modifiers: [.shift])
    ]

    private(set) var shortcuts: [ShortcutAction: Shortcut]
    var onAction: ((ShortcutAction) -> Void)?
    private let registrar: ShortcutRegistering
    private var notificationToken: NSObjectProtocol?

    init(
        registrar: ShortcutRegistering = CarbonShortcutRegistrar(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.registrar = registrar
        shortcuts = Self.defaultShortcuts
        for (action, shortcut) in shortcuts where action.requiresGlobalRegistration {
            _ = registrar.register(shortcut, action: action)
        }
        notificationToken = notificationCenter.addObserver(
            forName: .wpasteShortcut,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let rawValue = notification.object as? UInt32,
                  rawValue > 0,
                  ShortcutAction.allCases.indices.contains(Int(rawValue - 1)) else { return }
            let action = ShortcutAction.allCases[Int(rawValue - 1)]
            MainActor.assumeIsolated { self?.onAction?(action) }
        }
    }

    func update(_ action: ShortcutAction, to shortcut: Shortcut) -> ShortcutUpdateResult {
        if let conflict = shortcuts.first(where: { $0.key != action && $0.value == shortcut })?.key {
            return .internalConflict(conflict)
        }
        if action.requiresGlobalRegistration {
            guard registrar.register(shortcut, action: action) else { return .registrationFailed }
            if let old = shortcuts[action] { registrar.unregister(old) }
        }
        shortcuts[action] = shortcut
        return .success
    }

    func resetDefaults() {
        for (action, shortcut) in shortcuts where action.requiresGlobalRegistration {
            registrar.unregister(shortcut)
        }
        shortcuts = Self.defaultShortcuts
        for (action, shortcut) in shortcuts where action.requiresGlobalRegistration {
            _ = registrar.register(shortcut, action: action)
        }
    }
}

private extension ShortcutAction {
    var requiresGlobalRegistration: Bool {
        self == .showHistory
    }
}

@MainActor
final class CarbonShortcutRegistrar: ShortcutRegistering {
    private var references: [Shortcut: EventHotKeyRef] = [:]
    private var eventHandler: EventHandlerRef?

    init() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ in
                guard let event else { return OSStatus(eventNotHandledErr) }
                var identifier = EventHotKeyID()
                var size = MemoryLayout<EventHotKeyID>.size
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    &size,
                    &identifier
                )
                guard status == noErr else { return status }
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .wpasteShortcut, object: identifier.id)
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )
    }

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

private extension Notification.Name {
    static let wpasteShortcut = Notification.Name("WPasteShortcutPressed")
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
