import AppKit
import Testing
@testable import WPaste

@MainActor
struct PasteCoordinatorTests {
    private let source = ClipboardSource(bundleIdentifier: "com.apple.TextEdit", name: "文本编辑")

    @Test func capturedApplicationRemainsAvailableAfterCaptureScopeEnds() {
        let target = autoreleasepool {
            RunningApplicationTarget(application: NSRunningApplication(processIdentifier: ProcessInfo.processInfo.processIdentifier)!)
        }
        #expect(target.isRunning)
    }

    @Test func automaticPasteWritesClosesActivatesAndSendsInOrder() {
        var events: [String] = []
        let writer = RecordingPasteboardWriter { events.append($0) }
        let accessibility = RecordingAccessibilityClient(trusted: true) { events.append($0) }
        let target = RecordingApplicationTarget(isRunning: true) { events.append($0) }
        let coordinator = PasteCoordinator(
            pasteboard: writer,
            accessibility: accessibility,
            closeOverlay: { events.append("close") }
        )
        let item = ClipboardItem(payload: .text("hello"), fingerprint: "hello", source: source)

        let result = coordinator.paste(item: item, mode: .automatic(plainText: false), target: target)

        #expect(result == .pasted)
        #expect(events == ["write", "close", "activate", "paste"])
    }

    @Test func deniedAccessibilityFallsBackToCopyOnly() {
        var events: [String] = []
        let coordinator = PasteCoordinator(
            pasteboard: RecordingPasteboardWriter { events.append($0) },
            accessibility: RecordingAccessibilityClient(trusted: false) { events.append($0) },
            closeOverlay: { events.append("close") }
        )
        let item = ClipboardItem(payload: .text("hello"), fingerprint: "hello", source: source)

        let result = coordinator.paste(item: item, mode: .automatic(plainText: false), target: RecordingApplicationTarget(isRunning: true) { events.append($0) })

        #expect(result == .copiedOnly(.accessibilityPermissionMissing))
        #expect(events == ["write", "close", "permission"])
    }

    @Test func plainTextModeWritesStringRepresentation() {
        let writer = RecordingPasteboardWriter { _ in }
        let coordinator = PasteCoordinator(
            pasteboard: writer,
            accessibility: RecordingAccessibilityClient(trusted: true) { _ in },
            closeOverlay: {}
        )
        let item = ClipboardItem(payload: .url(URL(string: "https://example.com")!), fingerprint: "url", source: source)

        _ = coordinator.paste(item: item, mode: .copyOnly(plainText: true), target: nil)

        #expect(writer.lastPlainText == true)
        #expect(writer.lastPayload == item.payload)
    }

    @Test(arguments: [
        ClipboardPayload.text("hello"),
        ClipboardPayload.image(ImageMetadata(width: 10, height: 10, relativePath: "Images/test.png"))
    ])
    func repeatedDeniedPastesPromptOnlyOnceAndStillCopy(payload: ClipboardPayload) {
        var events: [String] = []
        let coordinator = PasteCoordinator(
            pasteboard: RecordingPasteboardWriter { events.append($0) },
            accessibility: RecordingAccessibilityClient(trusted: false) { events.append($0) },
            closeOverlay: { events.append("close") }
        )
        let item = ClipboardItem(payload: payload, fingerprint: "repeated", source: source)

        for _ in 0..<3 {
            #expect(coordinator.paste(item: item, mode: .automatic(plainText: false), target: nil)
                == .copiedOnly(.accessibilityPermissionMissing))
        }

        #expect(events.filter { $0 == "permission" }.count == 1)
        #expect(events.filter { $0 == "write" }.count == 3)
        #expect(!events.contains("paste"))
    }

    @Test func grantingPermissionAfterPromptRestoresAutomaticPaste() {
        var events: [String] = []
        let accessibility = RecordingAccessibilityClient(trusted: false) { events.append($0) }
        let coordinator = PasteCoordinator(
            pasteboard: RecordingPasteboardWriter { events.append($0) },
            accessibility: accessibility,
            closeOverlay: { events.append("close") }
        )
        let item = ClipboardItem(payload: .text("hello"), fingerprint: "hello", source: source)
        let target = RecordingApplicationTarget(isRunning: true) { events.append($0) }

        #expect(coordinator.paste(item: item, mode: .automatic(plainText: false), target: target)
            == .copiedOnly(.accessibilityPermissionMissing))
        accessibility.isTrusted = true
        #expect(coordinator.paste(item: item, mode: .automatic(plainText: false), target: target) == .pasted)
        #expect(events.filter { $0 == "permission" }.count == 1)
        #expect(events.suffix(2) == ["activate", "paste"])
    }

    @Test func exitedTargetLeavesContentCopied() {
        let coordinator = PasteCoordinator(
            pasteboard: RecordingPasteboardWriter { _ in },
            accessibility: RecordingAccessibilityClient(trusted: true) { _ in },
            closeOverlay: {}
        )
        let item = ClipboardItem(payload: .text("hello"), fingerprint: "hello", source: source)
        let target = RecordingApplicationTarget(isRunning: false) { _ in }
        #expect(coordinator.paste(item: item, mode: .automatic(plainText: false), target: target) == .copiedOnly(.targetUnavailable))
    }
}

@MainActor
private final class RecordingPasteboardWriter: PasteboardWriting {
    var lastPayload: ClipboardPayload?
    var lastPlainText: Bool?
    private let record: (String) -> Void

    init(record: @escaping (String) -> Void) { self.record = record }

    func write(_ payload: ClipboardPayload, asPlainText: Bool) -> Bool {
        lastPayload = payload
        lastPlainText = asPlainText
        record("write")
        return true
    }
}

@MainActor
private final class RecordingAccessibilityClient: AccessibilityControlling {
    var isTrusted: Bool
    let record: (String) -> Void

    init(trusted: Bool, record: @escaping (String) -> Void) {
        isTrusted = trusted
        self.record = record
    }

    func sendPasteCommand() -> Bool {
        record("paste")
        return true
    }

    func requestPermission() {
        record("permission")
    }
}

@MainActor
private final class RecordingApplicationTarget: ApplicationTargeting {
    let isRunning: Bool
    private let record: (String) -> Void

    init(isRunning: Bool, record: @escaping (String) -> Void) {
        self.isRunning = isRunning
        self.record = record
    }

    func activate() -> Bool {
        record("activate")
        return true
    }
}
