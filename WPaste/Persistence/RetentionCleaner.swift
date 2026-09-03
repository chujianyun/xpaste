import Foundation

@MainActor
struct RetentionCleaner {
    let repository: HistoryRepository

    @discardableResult
    func run(retention: HistoryRetention, now: Date = .now) throws -> Int {
        try repository.cleanExpired(retention: retention, now: now)
    }
}

