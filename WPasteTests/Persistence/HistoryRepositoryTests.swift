import Foundation
import Testing
@testable import WPaste

@MainActor
struct HistoryRepositoryTests {
    private let source = ClipboardSource(bundleIdentifier: "com.apple.TextEdit", name: "文本编辑")

    @Test func duplicateFingerprintUpdatesExistingItemAndMovesItFirst() throws {
        let repository = try HistoryRepository.inMemory()
        let start = Date(timeIntervalSince1970: 1_000)
        _ = try repository.upsert(payload: .text("first"), fingerprint: "same", source: source, at: start)
        _ = try repository.upsert(payload: .text("other"), fingerprint: "other", source: source, at: start.addingTimeInterval(1))
        _ = try repository.upsert(payload: .text("first updated"), fingerprint: "same", source: source, at: start.addingTimeInterval(2))

        let items = try repository.items()
        #expect(items.count == 2)
        #expect(items.map(\.fingerprint) == ["same", "other"])
        #expect(items.first?.payload == .text("first updated"))
    }

    @Test func sevenDayRetentionRemovesOnlyExpiredItems() throws {
        let repository = try HistoryRepository.inMemory()
        let now = Date(timeIntervalSince1970: 1_000_000)
        _ = try repository.upsert(payload: .text("expired"), fingerprint: "old", source: source, at: now.addingTimeInterval(-604_801))
        _ = try repository.upsert(payload: .text("kept"), fingerprint: "new", source: source, at: now.addingTimeInterval(-604_799))

        let removed = try repository.cleanExpired(retention: .sevenDays, now: now)

        #expect(removed == 1)
        #expect(try repository.items().map(\.fingerprint) == ["new"])
    }

    @Test func foreverRetentionDoesNotDeleteItems() throws {
        let repository = try HistoryRepository.inMemory()
        _ = try repository.upsert(payload: .text("kept"), fingerprint: "kept", source: source, at: .distantPast)
        #expect(try repository.cleanExpired(retention: .forever, now: .now) == 0)
        #expect(try repository.items().count == 1)
    }
}

