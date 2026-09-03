import Foundation

struct ClipboardParser: Sendable {
    func parse(_ snapshot: PasteboardSnapshot) -> ParsedClipboard? {
        if !snapshot.fileURLs.isEmpty {
            let files = snapshot.fileURLs.map {
                FileReference(path: $0.path, displayName: $0.lastPathComponent)
            }
            return ParsedClipboard(payload: .files(files), source: snapshot.source, declaredTypes: snapshot.declaredTypes)
        }

        if let imageData = snapshot.imageData, let size = snapshot.imageSize {
            return ParsedClipboard(
                payload: .image(.init(width: size.width, height: size.height, relativePath: "")),
                source: snapshot.source,
                declaredTypes: snapshot.declaredTypes,
                imageData: imageData
            )
        }

        if let rawURL = snapshot.urlString,
           let url = normalizedURL(from: rawURL) {
            return ParsedClipboard(payload: .url(url), source: snapshot.source, declaredTypes: snapshot.declaredTypes)
        }

        if let text = snapshot.text, !text.isEmpty {
            return ParsedClipboard(payload: .text(text), source: snapshot.source, declaredTypes: snapshot.declaredTypes)
        }

        return nil
    }

    private func normalizedURL(from rawValue: String) -> URL? {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: value),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              components.host != nil else { return nil }
        components.scheme = scheme
        components.host = components.host?.lowercased()
        return components.url
    }
}

