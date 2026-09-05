import AppKit
import SwiftUI
import Testing
@testable import WPaste

@MainActor
struct ClipboardCardViewTests {
    @Test func cardShowsInstalledSourceApplicationIconInBottomLeft() throws {
        try withCard(source: .init(bundleIdentifier: "com.apple.finder", name: "Finder")) { view in
            let iconView = try #require(sourceIcon(in: view))
            let image = try #require(iconView.image)
            #expect(image.isValid)
            #expect(iconView.toolTip == "Finder")
            let frame = iconView.convert(iconView.bounds, to: view)
            #expect(frame.midX < view.bounds.midX)
            let distanceFromBottom = view.isFlipped ? view.bounds.maxY - frame.midY : frame.midY
            #expect(distanceFromBottom < 28)
        }
    }

    @Test(arguments: [nil, "", "com.wpaste.missing-application.\(UUID().uuidString)"] as [String?])
    func cardOmitsIconWhenSourceApplicationCannotBeResolved(bundleIdentifier: String?) throws {
        // A familiar display name must not be used to guess an unrelated app's icon.
        try withCard(source: .init(bundleIdentifier: bundleIdentifier, name: "Finder")) { view in
            #expect(sourceIcon(in: view) == nil)
        }
    }

    private func sourceIcon(in view: NSView) -> NSImageView? {
        if let imageView = view as? NSImageView,
           imageView.accessibilityIdentifier() == "clipboard-source-icon" {
            return imageView
        }
        return view.subviews.lazy.compactMap { sourceIcon(in: $0) }.first
    }

    private func withCard(source: ClipboardSource, check: (NSView) throws -> Void) throws {
        let item = ClipboardItem(payload: .text("Example"), fingerprint: "example", source: source)
        let view = NSHostingView(rootView: ClipboardCardView(item: item, index: 0, isSelected: false))
        view.frame = NSRect(x: 0, y: 0, width: 238, height: 246)
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = view
        defer { window.orderOut(nil); window.contentView = nil }
        view.layoutSubtreeIfNeeded()
        try check(view)
    }
}
