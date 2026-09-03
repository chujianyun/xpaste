import CryptoKit
import Foundation

enum ContentFingerprint {
    static func make(for payload: ClipboardPayload) -> String {
        let canonical: Data
        switch payload {
        case let .text(text):
            canonical = Data("text\u{0}\(normalizeLineEndings(text))".utf8)
        case let .url(url):
            canonical = Data("url\u{0}\(url.absoluteString)".utf8)
        case let .image(metadata):
            canonical = Data("image\u{0}\(metadata.width)x\(metadata.height)\u{0}\(metadata.relativePath)".utf8)
        case let .files(files):
            canonical = Data("files\u{0}\(files.map(\.path).joined(separator: "\u{0}"))".utf8)
        }
        return SHA256.hash(data: canonical).map { String(format: "%02x", $0) }.joined()
    }

    static func make(forImageData data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func normalizeLineEndings(_ value: String) -> String {
        value.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }
}

