import AppKit
import Foundation

@MainActor
protocol PasteboardReading: AnyObject {
    var changeCount: Int { get }
    func snapshot() -> PasteboardSnapshot?
}

@MainActor
final class SystemPasteboardClient: PasteboardReading {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    var changeCount: Int { pasteboard.changeCount }

    func snapshot() -> PasteboardSnapshot? {
        let app = NSWorkspace.shared.frontmostApplication
        let source = ClipboardSource(
            bundleIdentifier: app?.bundleIdentifier,
            name: app?.localizedName ?? "未知应用"
        )
        let fileURLs = (pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL]) ?? []
        let imageData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff)
        let imageSize = imageData.flatMap(NSImage.init(data:)).map {
            PixelSize(width: Int($0.size.width), height: Int($0.size.height))
        }
        let declaredTypes = Set((pasteboard.types ?? []).map(\.rawValue))
        return PasteboardSnapshot(
            fileURLs: fileURLs,
            imageData: imageData,
            imageSize: imageSize,
            urlString: pasteboard.string(forType: .URL),
            text: pasteboard.string(forType: .string),
            declaredTypes: declaredTypes,
            source: source
        )
    }
}

