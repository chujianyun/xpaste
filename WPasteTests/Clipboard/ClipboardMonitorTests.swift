import Foundation
import Testing
@testable import WPaste

@MainActor
struct ClipboardMonitorTests {
    private let source = ClipboardSource(bundleIdentifier: "com.apple.TextEdit", name: "文本编辑")

    @Test func capturesExactlyOnceForEachChangeCount() throws {
        let pasteboard = FakePasteboardClient(snapshot: .init(text: "hello", source: source))
        let repository = try HistoryRepository.inMemory()
        let monitor = ClipboardMonitor(pasteboard: pasteboard, repository: repository) { .default }

        try monitor.pollOnce(now: Date(timeIntervalSince1970: 100))
        #expect(try repository.items().isEmpty)

        pasteboard.changeCount = 1
        try monitor.pollOnce(now: Date(timeIntervalSince1970: 101))
        try monitor.pollOnce(now: Date(timeIntervalSince1970: 102))
        #expect(try repository.items().count == 1)
    }

    @Test func privacyFilteringHappensBeforePersistence() throws {
        let pasteboard = FakePasteboardClient(snapshot: .init(
            text: "secret",
            declaredTypes: ["org.nspasteboard.ConcealedType"],
            source: source
        ))
        let repository = try HistoryRepository.inMemory()
        let monitor = ClipboardMonitor(pasteboard: pasteboard, repository: repository) { .default }
        pasteboard.changeCount = 1

        try monitor.pollOnce()

        #expect(try repository.items().isEmpty)
    }

    @Test func appWriteSuppressionSkipsMatchingNextCapture() throws {
        let pasteboard = FakePasteboardClient(snapshot: .init(text: "self write", source: source))
        let repository = try HistoryRepository.inMemory()
        let monitor = ClipboardMonitor(pasteboard: pasteboard, repository: repository) { .default }
        let payload = ClipboardPayload.text("self write")
        let now = Date(timeIntervalSince1970: 200)
        monitor.suppressNextWrite(fingerprint: ContentFingerprint.make(for: payload), until: now.addingTimeInterval(2))
        pasteboard.changeCount = 1

        try monitor.pollOnce(now: now)

        #expect(try repository.items().isEmpty)
    }
}

@MainActor
private final class FakePasteboardClient: PasteboardReading {
    var changeCount = 0
    var snapshotValue: PasteboardSnapshot

    init(snapshot: PasteboardSnapshot) {
        snapshotValue = snapshot
    }

    func snapshot() -> PasteboardSnapshot? {
        snapshotValue
    }
}

