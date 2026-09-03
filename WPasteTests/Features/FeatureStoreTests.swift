import Foundation
import Testing
@testable import WPaste

@MainActor
struct FeatureStoreTests {
    private let source = ClipboardSource(bundleIdentifier: "com.apple.Safari", name: "Safari")

    @Test func historySearchMatchesTextURLFilenameAndSource() throws {
        let repository = try HistoryRepository.inMemory()
        _ = try repository.upsert(payload: .text("季度计划"), fingerprint: "text", source: source)
        _ = try repository.upsert(payload: .url(URL(string: "https://example.com/docs")!), fingerprint: "url", source: source)
        _ = try repository.upsert(payload: .files([.init(path: "/tmp/report.pdf", displayName: "report.pdf")]), fingerprint: "file", source: source)
        let store = HistoryStore(repository: repository)

        try store.reload()
        store.query = "REPORT"
        #expect(store.filteredItems.map(\.fingerprint) == ["file"])
        store.query = "safari"
        #expect(store.filteredItems.count == 3)
    }

    @Test func itemCanBelongToMultiplePinboardsAndDeletingBoardKeepsHistory() throws {
        let repository = try HistoryRepository.inMemory()
        let item = try repository.upsert(payload: .text("keep"), fingerprint: "keep", source: source)
        let store = PinboardStore(repository: repository)
        let work = try store.create(name: "工作")
        let later = try store.create(name: "稍后")
        try store.add(itemID: item.id, to: work.id)
        try store.add(itemID: item.id, to: later.id)

        #expect(try store.itemIDs(in: work.id) == [item.id])
        #expect(try store.itemIDs(in: later.id) == [item.id])
        try store.delete(id: work.id)
        #expect(try repository.items().map(\.id) == [item.id])
        #expect(try store.itemIDs(in: later.id) == [item.id])
    }

    @Test func pasteStackReordersAndOnlyAdvancesAfterAutomaticPaste() throws {
        let repository = try HistoryRepository.inMemory()
        let first = try repository.upsert(payload: .text("first"), fingerprint: "first", source: source)
        let second = try repository.upsert(payload: .text("second"), fingerprint: "second", source: source)
        let stack = PasteStackStore(repository: repository)
        try stack.add(first.id)
        try stack.add(second.id)
        try stack.move(from: 1, to: 0)
        #expect(try stack.items().map(\.id) == [second.id, first.id])

        try stack.completeFirst(successfullyPasted: false)
        #expect(try stack.items().count == 2)
        try stack.completeFirst(successfullyPasted: true)
        #expect(try stack.items().map(\.id) == [first.id])
    }

    @Test func pinboardsCanBeRenamedAndReordered() throws {
        let repository = try HistoryRepository.inMemory()
        let store = PinboardStore(repository: repository)
        let first = try store.create(name: "第一")
        _ = try store.create(name: "第二")
        let third = try store.create(name: "第三")

        try store.rename(id: first.id, name: "已重命名")
        try store.move(id: third.id, to: 0)

        #expect(store.pinboards.map(\.name) == ["第三", "已重命名", "第二"])
    }
}
