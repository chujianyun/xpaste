import Foundation
import SwiftData

@MainActor
final class HistoryRepository {
    private let container: ModelContainer
    private let context: ModelContext

    init(inMemory: Bool = false) throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        container = try ModelContainer(for: HistoryRecord.self, configurations: configuration)
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

