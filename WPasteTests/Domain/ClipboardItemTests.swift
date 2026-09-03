import Foundation
import Testing
@testable import WPaste

struct ClipboardItemTests {
    @Test func payloadKindsHaveStableLabels() {
        #expect(ClipboardPayload.text("hello").kindLabel == "文本")
        #expect(ClipboardPayload.url(URL(string: "https://example.com")!).kindLabel == "链接")
        #expect(ClipboardPayload.image(.init(width: 10, height: 20, relativePath: "a.png")).kindLabel == "图片")
        #expect(ClipboardPayload.files([.init(path: "/tmp/a", displayName: "a")]).kindLabel == "1 个文件")
        #expect(ClipboardPayload.files([
            .init(path: "/tmp/a", displayName: "a"),
            .init(path: "/tmp/b", displayName: "b")
        ]).kindLabel == "2 个文件")
    }

    @Test func clipboardItemsUseIdentityEquality() {
        let id = UUID()
        let source = ClipboardSource(bundleIdentifier: "com.apple.TextEdit", name: "文本编辑")
        let first = ClipboardItem(id: id, payload: .text("hello"), fingerprint: "abc", source: source)
        let second = ClipboardItem(id: id, payload: .text("changed"), fingerprint: "def", source: source)
        #expect(first == second)
    }

    @Test func settingsDefaultToSevenDaysAndAutomaticPaste() {
        let settings = AppSettings.default
        #expect(settings.retention == .sevenDays)
        #expect(settings.defaultPasteBehavior == .automatic)
        #expect(settings.defaultPlainText == false)
    }
}

