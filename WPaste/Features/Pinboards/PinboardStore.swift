import Foundation
import Observation

@MainActor
@Observable
final class PinboardStore {
    private(set) var pinboards: [Pinboard] = []
    private let repository: HistoryRepository

    init(repository: HistoryRepository) {
        self.repository = repository
        try? reload()
    }

    @discardableResult
    func create(name: String) throws -> Pinboard {
        let pinboard = try repository.createPinboard(name: name)
        try reload()
        return pinboard
    }

    func rename(id: UUID, name: String) throws {
        try repository.renamePinboard(id: id, name: name)
        try reload()
    }

    func delete(id: UUID) throws {
        try repository.deletePinboard(id: id)
        try reload()
    }

    func add(itemID: UUID, to pinboardID: UUID) throws {
        try repository.add(itemID: itemID, toPinboard: pinboardID)
    }

    func itemIDs(in pinboardID: UUID) throws -> [UUID] {
        try repository.itemIDs(inPinboard: pinboardID)
    }

    func reload() throws {
        pinboards = try repository.pinboards()
    }
}

