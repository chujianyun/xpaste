import Foundation
import Testing
@testable import WPaste

@MainActor
struct ClipboardLifecycleTests {
    @Test func imageCapturePersistsFileAndHistoryDeletionRemovesIt() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: root) }
        let imageStore = ImageFileStore(rootDirectory: root)
        let repository = try HistoryRepository.inMemory(imageFileStore: imageStore)
        let pasteboard = IntegrationPasteboard(snapshot: .init(
            imageData: Data([1, 2, 3, 4]),
            imageSize: .init(width: 64, height: 32),
            source: .init(bundleIdentifier: "com.example.image", name: "Image App")
        ))
        let monitor = ClipboardMonitor(pasteboard: pasteboard, repository: repository) { .default }
        pasteboard.changeCount = 1

        try monitor.pollOnce()

        let item = try #require(repository.items().first)
        guard case let .image(metadata) = item.payload else {
            Issue.record("Expected an image item")
            return
        }
        #expect(imageStore.exists(relativePath: metadata.relativePath))
        try repository.delete(id: item.id)
        #expect(imageStore.exists(relativePath: metadata.relativePath) == false)
    }

    @Test func deletingHistoryCascadesPinboardAndStackReferences() throws {
        let repository = try HistoryRepository.inMemory()
        let source = ClipboardSource(bundleIdentifier: nil, name: "Test")
        let item = try repository.upsert(payload: .text("value"), fingerprint: "value", source: source)
        let board = try repository.createPinboard(name: "Board")
        try repository.add(itemID: item.id, toPinboard: board.id)
        try repository.addToStack(itemID: item.id)

        try repository.delete(id: item.id)

        #expect(try repository.itemIDs(inPinboard: board.id).isEmpty)
        #expect(try repository.stackItemIDs().isEmpty)
    }

    @Test func replacingDuplicateImageDeletesSupersededFile() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: root) }
        let imageStore = ImageFileStore(rootDirectory: root)
        let repository = try HistoryRepository.inMemory(imageFileStore: imageStore)
        let source = ClipboardSource(bundleIdentifier: nil, name: "Image App")
        let first = ParsedClipboard(
            payload: .image(.init(width: 10, height: 10, relativePath: "")),
            source: source,
            imageData: Data([1])
        )
        let second = ParsedClipboard(
            payload: .image(.init(width: 20, height: 20, relativePath: "")),
            source: source,
            imageData: Data([2])
        )
        let firstItem = try repository.upsert(candidate: first, fingerprint: "same", at: .distantPast)
        guard case let .image(firstMetadata) = firstItem.payload else { return }

        _ = try repository.upsert(candidate: second, fingerprint: "same", at: .now)

        #expect(imageStore.exists(relativePath: firstMetadata.relativePath) == false)
    }
}

@MainActor
private final class IntegrationPasteboard: PasteboardReading {
    var changeCount = 0
    let value: PasteboardSnapshot
    init(snapshot: PasteboardSnapshot) { value = snapshot }
    func snapshot() -> PasteboardSnapshot? { value }
}
