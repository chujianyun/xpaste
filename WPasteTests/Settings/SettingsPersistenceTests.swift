import Foundation
import Testing
@testable import WPaste

struct SettingsPersistenceTests {
    @Test func missingSettingsLoadProductDefaults() {
        let defaults = isolatedDefaults()
        let store = SettingsPersistence(defaults: defaults)
        #expect(store.load() == .default)
    }

    @Test func savesAndRestoresAllPrivacyAndGeneralSettings() throws {
        let defaults = isolatedDefaults()
        let store = SettingsPersistence(defaults: defaults)
        var settings = AppSettings.default
        settings.retention = .oneMonth
        settings.defaultPasteBehavior = .copyOnly
        settings.ignoredBundleIdentifiers = ["com.example.private"]
        settings.clearHistoryOnQuit = true

        try store.save(settings)

        #expect(store.load() == settings)
    }

    @Test func onboardingIsRequiredOnlyUntilAcknowledged() {
        let defaults = isolatedDefaults()
        let store = OnboardingStateStore(defaults: defaults)
        #expect(store.isRequired)
        store.acknowledge()
        #expect(store.isRequired == false)
    }

    @Test func shortcutOverridesRoundTrip() throws {
        let defaults = isolatedDefaults()
        let store = ShortcutPersistence(defaults: defaults)
        let shortcut = Shortcut(keyCode: 42, modifiers: [.command, .option])
        try store.save([.showHistory: shortcut])
        #expect(store.load() == [.showHistory: shortcut])
    }

    private func isolatedDefaults() -> UserDefaults {
        let suite = "WPasteTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
