import Foundation
import SwiftUI
import Testing
@testable import WPaste

struct SettingsPersistenceTests {
    @Test @MainActor func settingsTitlebarBlendsWithSidebarAndKeepsNativeControls() throws {
        let model = AppModel(settings: .default)
        defer { model.stop() }
        let view = NSHostingView(rootView: SettingsView(model: model))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false
        )
        window.contentView = view
        defer { window.orderOut(nil); window.contentView = nil }
        view.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))

        #expect(window.titlebarAppearsTransparent)
        #expect(window.titlebarSeparatorStyle == .none)
        #expect(window.toolbarStyle == .unified)
        for kind in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            let button = try #require(window.standardWindowButton(kind))
            #expect(!button.isHidden)
        }
    }

    @Test @MainActor func settingsWindowUsesWideCompactLayout() {
        let model = AppModel(settings: .default)
        defer { model.stop() }
        let view = NSHostingView(rootView: SettingsView(model: model))
        let size = view.fittingSize

        #expect(size.width == 900)
        #expect(size.height <= 500)
        #expect(size.width / size.height >= 1.5)
    }

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

    @Test func shortcutLoadingIgnoresRemovedActionsAndKeepsKnownOverrides() throws {
        let defaults = isolatedDefaults()
        let store = ShortcutPersistence(defaults: defaults)
        defaults.set(
            Data("""
            [
              {"action":"showHistory","shortcut":{"keyCode":42,"modifiers":3}},
              {"action":"showPasteStack","shortcut":{"keyCode":8,"modifiers":9}}
            ]
            """.utf8),
            forKey: "WPaste.Shortcuts.v1"
        )

        #expect(store.load() == [
            .showHistory: Shortcut(keyCode: 42, modifiers: [.command, .option])
        ])
    }

    private func isolatedDefaults() -> UserDefaults {
        let suite = "WPasteTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
