import Foundation
import SwiftData

@MainActor
final class HistoryRepository {
    private let container: ModelContainer
    private let context: ModelContext

    init(inMemory: Bool = false) throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        container = try ModelContainer(
            for: HistoryRecord.self,
            PinboardRecord.self,
            PinboardItemRecord.self,
            StackEntryRecord.self,
            configurations: configuration
        )
        context = container.mainContext
        context.autosaveEnabled = false
    }

    static func inMemory() throws -> HistoryRepository {
        try HistoryRepository(inMemory: true)
    }

    @discardableResult
    func upsert(
        payload: ClipboardPayload,
        fingerprint: String,
        source: ClipboardSource,
        at date: Date = .now
    ) throws -> ClipboardItem {
        let descriptor = FetchDescriptor<HistoryRecord>(predicate: #Predicate { $0.fingerprint == fingerprint })
        if let existing = try context.fetch(descriptor).first {
            let item = ClipboardItem(
                id: existing.id,
                payload: payload,
                fingerprint: fingerprint,
                source: source,
                createdAt: existing.createdAt,
                lastUsedAt: date
            )
            try existing.update(from: item)
            try context.save()
            return item
        }

        let item = ClipboardItem(
            payload: payload,
            fingerprint: fingerprint,
            source: source,
            createdAt: date,
            lastUsedAt: date
        )
        context.insert(try HistoryRecord(item: item))
        try context.save()
        return item
    }

    func items() throws -> [ClipboardItem] {
        var descriptor = FetchDescriptor<HistoryRecord>(sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)])
        descriptor.includePendingChanges = true
        return try context.fetch(descriptor).compactMap { try? $0.domainItem() }
    }

    func delete(id: UUID) throws {
        let descriptor = FetchDescriptor<HistoryRecord>(predicate: #Predicate { $0.id == id })
        try context.fetch(descriptor).forEach(context.delete)
        let memberships = FetchDescriptor<PinboardItemRecord>(predicate: #Predicate { $0.itemID == id })
        try context.fetch(memberships).forEach(context.delete)
        let stackEntries = FetchDescriptor<StackEntryRecord>(predicate: #Predicate { $0.itemID == id })
        try context.fetch(stackEntries).forEach(context.delete)
        try context.save()
    }

    func clear() throws {
        try context.delete(model: HistoryRecord.self)
        try context.save()
    }

    @discardableResult
    func cleanExpired(retention: HistoryRetention, now: Date = .now) throws -> Int {
        guard let interval = retention.duration else { return 0 }
        let cutoff = now.addingTimeInterval(-interval)
        let descriptor = FetchDescriptor<HistoryRecord>(predicate: #Predicate { $0.lastUsedAt < cutoff })
        let expired = try context.fetch(descriptor)
        expired.forEach(context.delete)
        try context.save()
        return expired.count
    }

    func pinboards() throws -> [Pinboard] {
        let descriptor = FetchDescriptor<PinboardRecord>(sortBy: [SortDescriptor(\.order)])
        return try context.fetch(descriptor).map { Pinboard(id: $0.id, name: $0.name, order: $0.order) }
    }

    func createPinboard(name: String) throws -> Pinboard {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let record = PinboardRecord(name: cleanName, order: try pinboards().count)
        context.insert(record)
        try context.save()
        return Pinboard(id: record.id, name: record.name, order: record.order)
    }

    func renamePinboard(id: UUID, name: String) throws {
        let descriptor = FetchDescriptor<PinboardRecord>(predicate: #Predicate { $0.id == id })
        guard let record = try context.fetch(descriptor).first else { return }
        record.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        try context.save()
    }

    func deletePinboard(id: UUID) throws {
        let descriptor = FetchDescriptor<PinboardRecord>(predicate: #Predicate { $0.id == id })
        try context.fetch(descriptor).forEach(context.delete)
        let memberships = FetchDescriptor<PinboardItemRecord>(predicate: #Predicate { $0.pinboardID == id })
        try context.fetch(memberships).forEach(context.delete)
        try context.save()
    }

    func add(itemID: UUID, toPinboard pinboardID: UUID) throws {
        let descriptor = FetchDescriptor<PinboardItemRecord>(predicate: #Predicate {
            $0.itemID == itemID && $0.pinboardID == pinboardID
        })
        guard try context.fetch(descriptor).isEmpty else { return }
        context.insert(PinboardItemRecord(pinboardID: pinboardID, itemID: itemID))
        try context.save()
    }

    func itemIDs(inPinboard pinboardID: UUID) throws -> [UUID] {
        let descriptor = FetchDescriptor<PinboardItemRecord>(predicate: #Predicate { $0.pinboardID == pinboardID })
        return try context.fetch(descriptor).map(\.itemID)
    }

    func addToStack(itemID: UUID) throws {
        let existing = try stackItemIDs()
        guard !existing.contains(itemID) else { return }
        context.insert(StackEntryRecord(itemID: itemID, order: existing.count))
        try context.save()
    }

    func stackItemIDs() throws -> [UUID] {
        let descriptor = FetchDescriptor<StackEntryRecord>(sortBy: [SortDescriptor(\.order)])
        return try context.fetch(descriptor).map(\.itemID)
    }

    func moveStackItem(from source: Int, to destination: Int) throws {
        let descriptor = FetchDescriptor<StackEntryRecord>(sortBy: [SortDescriptor(\.order)])
        var entries = try context.fetch(descriptor)
        guard entries.indices.contains(source), destination >= 0, destination < entries.count else { return }
        let moved = entries.remove(at: source)
        entries.insert(moved, at: destination)
        for (index, entry) in entries.enumerated() { entry.order = index }
        try context.save()
    }

    func removeFirstStackItem() throws {
        let descriptor = FetchDescriptor<StackEntryRecord>(sortBy: [SortDescriptor(\.order)])
        let entries = try context.fetch(descriptor)
        guard let first = entries.first else { return }
        context.delete(first)
        for (index, entry) in entries.dropFirst().enumerated() { entry.order = index }
        try context.save()
    }

    func removeStackItem(id: UUID) throws {
        let descriptor = FetchDescriptor<StackEntryRecord>(predicate: #Predicate { $0.itemID == id })
        try context.fetch(descriptor).forEach(context.delete)
        try normalizeStackOrder()
    }

    func clearStack() throws {
        try context.delete(model: StackEntryRecord.self)
        try context.save()
    }

    private func normalizeStackOrder() throws {
        let descriptor = FetchDescriptor<StackEntryRecord>(sortBy: [SortDescriptor(\.order)])
        for (index, entry) in try context.fetch(descriptor).enumerated() { entry.order = index }
        try context.save()
    }
}

private extension HistoryRetention {
    var duration: TimeInterval? {
        switch self {
        case .oneDay: 86_400
        case .sevenDays: 604_800
        case .oneMonth: 2_592_000
        case .oneYear: 31_536_000
        case .forever: nil
        }
    }
}
