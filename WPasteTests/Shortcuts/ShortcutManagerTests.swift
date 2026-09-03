import Testing
@testable import WPaste

@MainActor
struct ShortcutManagerTests {
    @Test func rejectsDuplicateChordWithoutChangingExistingShortcut() {
        let registrar = FakeShortcutRegistrar()
        let manager = ShortcutManager(registrar: registrar)
        let original = manager.shortcuts[.showHistory]

        let result = manager.update(.showHistory, to: manager.shortcuts[.showPasteStack]!)

        #expect(result == .internalConflict(.showPasteStack))
        #expect(manager.shortcuts[.showHistory] == original)
    }

    @Test func failedSystemRegistrationKeepsOldShortcutRegistered() {
        let registrar = FakeShortcutRegistrar()
        let manager = ShortcutManager(registrar: registrar)
        let original = manager.shortcuts[.showHistory]!
        let replacement = Shortcut(keyCode: 8, modifiers: [.command, .option])
        registrar.rejected = replacement

        let result = manager.update(.showHistory, to: replacement)

        #expect(result == .registrationFailed)
        #expect(manager.shortcuts[.showHistory] == original)
        #expect(registrar.registered.contains(original))
    }

    @Test func resetRestoresDefaultShortcuts() {
        let registrar = FakeShortcutRegistrar()
        let manager = ShortcutManager(registrar: registrar)
        _ = manager.update(.showHistory, to: .init(keyCode: 9, modifiers: [.command, .option]))
        manager.resetDefaults()
        #expect(manager.shortcuts == ShortcutManager.defaultShortcuts)
    }
}

@MainActor
private final class FakeShortcutRegistrar: ShortcutRegistering {
    var registered: Set<Shortcut> = []
    var rejected: Shortcut?

    func register(_ shortcut: Shortcut, action: ShortcutAction) -> Bool {
        guard shortcut != rejected else { return false }
        registered.insert(shortcut)
        return true
    }

    func unregister(_ shortcut: Shortcut) {
        registered.remove(shortcut)
    }
}

