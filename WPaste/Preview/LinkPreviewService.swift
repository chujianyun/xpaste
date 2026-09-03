import Foundation
import LinkPresentation

struct LinkPreview: Sendable {
    let title: String?
    let originalURL: URL
}

@MainActor
final class LinkPreviewService {
    private var cache: [URL: LinkPreview] = [:]

    func preview(for url: URL, enabled: Bool) async -> LinkPreview? {
        guard enabled else { return nil }
        if let cached = cache[url] { return cached }
        let provider = LPMetadataProvider()
        guard let metadata = try? await provider.startFetchingMetadata(for: url) else { return nil }
        let preview = LinkPreview(title: metadata.title, originalURL: metadata.originalURL ?? url)
        cache[url] = preview
        return preview
    }

    func clearCache() {
        cache.removeAll()
    }
}

