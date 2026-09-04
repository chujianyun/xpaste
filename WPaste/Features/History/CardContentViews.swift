import AppKit
import SwiftUI

struct TextCardContent: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(.system(size: 14))
                .lineLimit(7)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            Text("\(text.count) 个字符")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

struct URLCardContent: View {
    let url: URL
    let previewsEnabled: Bool
    @State private var preview: LinkPreview?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "link")
                .font(.system(size: 38))
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
            Text(preview?.title ?? url.host() ?? url.absoluteString)
                .font(.headline)
            Text(url.absoluteString)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .task(id: url) {
            preview = await LinkPreviewService().preview(for: url, enabled: previewsEnabled)
        }
    }
}

struct ImageCardContent: View {
    let metadata: ImageMetadata

    var body: some View {
        VStack(spacing: 8) {
            if let image = loadImage() {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView("预览不可用", systemImage: "photo")
            }
            Text("\(metadata.width) × \(metadata.height)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func loadImage() -> NSImage? {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "WPaste", directoryHint: .isDirectory)
        return NSImage(contentsOf: root.appending(path: metadata.relativePath))
    }
}

struct FilesCardContent: View {
    let files: [FileReference]

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: files.count == 1 ? "doc.fill" : "doc.on.doc.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white, .blue)
                .frame(maxHeight: .infinity)
            Text(files.count == 1 ? files[0].displayName : "多个文件")
                .font(.headline)
                .lineLimit(1)
            if files.contains(where: { !FileManager.default.fileExists(atPath: $0.path) }) {
                Label("文件已不存在", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }
}
