import Foundation
import Observation

@MainActor
@Observable
final class HistoryStore {
    var query = ""
    private(set) var items: [ClipboardItem] = []
    private let repository: HistoryRepository

    init(repository: HistoryRepository) {
        self.repository = repository
    }

    var filteredItems: [ClipboardItem] {
        let needle = query.searchNormalized
        guard !needle.isEmpty else { return items }
        return items.filter { item in
            item.searchableText.searchNormalized.contains(needle)
        }
    }

    func reload() throws {
        items = try repository.items()
    }

    func delete(id: UUID) throws {
        try repository.delete(id: id)
        try reload()
    }
}

private extension String {
    var searchNormalized: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

private extension ClipboardItem {
    var searchableText: String {
        let payloadText: String
        switch payload {
        case let .text(value): payloadText = value
        case let .url(value): payloadText = value.absoluteString
        case let .image(value): payloadText = "\(value.width) \(value.height)"
        case let .files(value): payloadText = value.map(\.displayName).joined(separator: " ")
        }
        return "\(payloadText) \(source.name) \(source.bundleIdentifier ?? "")"
    }
}

