import Foundation
import SwiftData

@Model
final class HistoryRecord {
    @Attribute(.unique) var fingerprint: String
    var id: UUID
    var kind: String
    var textValue: String?
    var urlValue: String?
    var imageWidth: Int?
    var imageHeight: Int?
    var imageRelativePath: String?
    var filesData: Data?
    var sourceBundleIdentifier: String?
    var sourceName: String
    var createdAt: Date
    var lastUsedAt: Date

    init(item: ClipboardItem) throws {
        id = item.id
        fingerprint = item.fingerprint
        kind = ""
        sourceBundleIdentifier = item.source.bundleIdentifier
        sourceName = item.source.name
        createdAt = item.createdAt
        lastUsedAt = item.lastUsedAt
        try updatePayload(item.payload)
    }

    func update(from item: ClipboardItem) throws {
        sourceBundleIdentifier = item.source.bundleIdentifier
        sourceName = item.source.name
        lastUsedAt = item.lastUsedAt
        try updatePayload(item.payload)
    }

    func domainItem() throws -> ClipboardItem {
        let payload: ClipboardPayload
        switch kind {
        case "text":
            payload = .text(textValue ?? "")
        case "url":
            guard let value = urlValue, let url = URL(string: value) else { throw PersistenceError.corruptRecord }
            payload = .url(url)
        case "image":
            guard let width = imageWidth, let height = imageHeight, let path = imageRelativePath else { throw PersistenceError.corruptRecord }
            payload = .image(.init(width: width, height: height, relativePath: path))
        case "files":
            guard let filesData else { throw PersistenceError.corruptRecord }
            payload = .files(try JSONDecoder().decode([FileReference].self, from: filesData))
        default:
            throw PersistenceError.corruptRecord
        }
        return ClipboardItem(
            id: id,
            payload: payload,
            fingerprint: fingerprint,
            source: .init(bundleIdentifier: sourceBundleIdentifier, name: sourceName),
            createdAt: createdAt,
            lastUsedAt: lastUsedAt
        )
    }

    private func updatePayload(_ payload: ClipboardPayload) throws {
        textValue = nil
        urlValue = nil
        imageWidth = nil
        imageHeight = nil
        imageRelativePath = nil
        filesData = nil
        switch payload {
        case let .text(value):
            kind = "text"
            textValue = value
        case let .url(value):
            kind = "url"
            urlValue = value.absoluteString
        case let .image(value):
            kind = "image"
            imageWidth = value.width
            imageHeight = value.height
            imageRelativePath = value.relativePath
        case let .files(value):
            kind = "files"
            filesData = try JSONEncoder().encode(value)
        }
    }
}

enum PersistenceError: Error, Equatable {
    case corruptRecord
}

