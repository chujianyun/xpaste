import Testing
@testable import WPaste

struct PrivacyFilterTests {
    private let payload = ClipboardPayload.text("secret")

    @Test func pauseRejectsEveryCapture() {
        var settings = AppSettings.default
        settings.recordingPaused = true
        let candidate = ParsedClipboard(payload: payload, source: .init(bundleIdentifier: "com.apple.TextEdit", name: "文本编辑"))
        #expect(PrivacyFilter().decision(for: candidate, settings: settings) == .reject(.recordingPaused))
    }

    @Test func ignoredAppsAndPasswordManagersAreRejected() {
        var settings = AppSettings.default
        settings.ignoredBundleIdentifiers = ["com.example.private"]
        let ignored = ParsedClipboard(payload: payload, source: .init(bundleIdentifier: "com.example.private", name: "Private"))
        let passwordManager = ParsedClipboard(payload: payload, source: .init(bundleIdentifier: "com.agilebits.onepassword7", name: "1Password"))

        #expect(PrivacyFilter().decision(for: ignored, settings: settings) == .reject(.ignoredApplication))
        #expect(PrivacyFilter().decision(for: passwordManager, settings: settings) == .reject(.passwordManager))
    }

    @Test func confidentialAndTransientTypesRespectSettings() {
        let confidential = ParsedClipboard(
            payload: payload,
            source: .init(bundleIdentifier: nil, name: "未知应用"),
            declaredTypes: ["org.nspasteboard.ConcealedType"]
        )
        let transient = ParsedClipboard(
            payload: payload,
            source: .init(bundleIdentifier: nil, name: "未知应用"),
            declaredTypes: ["org.nspasteboard.TransientType"]
        )

        #expect(PrivacyFilter().decision(for: confidential, settings: .default) == .reject(.sensitiveContent))
        #expect(PrivacyFilter().decision(for: transient, settings: .default) == .reject(.transientContent))
    }

    @Test func ordinaryContentIsAllowed() {
        let candidate = ParsedClipboard(payload: payload, source: .init(bundleIdentifier: "com.apple.TextEdit", name: "文本编辑"))
        #expect(PrivacyFilter().decision(for: candidate, settings: .default) == .allow)
    }
}

