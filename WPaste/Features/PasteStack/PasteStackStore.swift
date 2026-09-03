import Foundation
import Observation

@MainActor
@Observable
final class PasteStackStore {
    private let repository: HistoryRepository

    init(repository: HistoryRepository) {
        self.repository = repository
    }

    func add(_ itemID: UUID) throws {
        try repository.addToStack(itemID: itemID)
    }

    func items() throws -> [ClipboardItem] {
        let itemByID = Dictionary(uniqueKeysWithValues: try repository.items().map { ($0.id, $0) })
        return try repository.stackItemIDs().compactMap { itemByID[$0] }
    }

    func move(from source: Int, to destination: Int) throws {
        try repository.moveStackItem(from: source, to: destination)
    }

    func remove(_ itemID: UUID) throws {
        try repository.removeStackItem(id: itemID)
    }

    func clear() throws {
        try repository.clearStack()
    }

    func completeFirst(successfullyPasted: Bool) throws {
        guard successfullyPasted else { return }
        try repository.removeFirstStackItem()
    }
}

