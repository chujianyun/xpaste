import Foundation
import Testing
@testable import WPaste

struct ClipboardParserTests {
    @Test func filesTakePriorityOverOtherRepresentations() {
        let snapshot = PasteboardSnapshot(
            fileURLs: [URL(fileURLWithPath: "/tmp/report.pdf")],
            imageData: Data([1, 2, 3]),
            imageSize: .init(width: 12, height: 8),
            urlString: "https://example.com",
            text: "fallback",
            source: .init(bundleIdentifier: "com.apple.finder", name: "Finder")
        )

        let parsed = ClipboardParser().parse(snapshot)

        #expect(parsed?.payload == .files([.init(path: "/tmp/report.pdf", displayName: "report.pdf")]))
    }

    @Test func parserRecognizesImageURLAndText() {
        let source = ClipboardSource(bundleIdentifier: nil, name: "未知应用")
        let image = ClipboardParser().parse(.init(
            imageData: Data([9, 8]),
            imageSize: .init(width: 20, height: 10),
            source: source
        ))
        let url = ClipboardParser().parse(.init(urlString: " HTTPS://Example.COM/path ", source: source))
        let text = ClipboardParser().parse(.init(text: "hello", source: source))

        #expect(image?.payload == .image(.init(width: 20, height: 10, relativePath: "")))
        #expect(url?.payload == .url(URL(string: "https://example.com/path")!))
        #expect(text?.payload == .text("hello"))
    }

    @Test func emptyClipboardIsIgnored() {
        #expect(ClipboardParser().parse(.init(source: .init(bundleIdentifier: nil, name: "未知应用"))) == nil)
    }

    @Test func semanticallyEqualTextHasStableFingerprint() {
        let first = ContentFingerprint.make(for: .text("line 1\r\nline 2"))
        let second = ContentFingerprint.make(for: .text("line 1\nline 2"))
        #expect(first == second)
        #expect(first.count == 64)
    }
}

