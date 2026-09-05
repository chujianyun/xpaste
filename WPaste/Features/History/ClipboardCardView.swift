import AppKit
import SwiftUI

struct ClipboardCardView: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    var linkPreviewsEnabled = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                Text(item.payload.kindLabel)
                    .font(.headline)
                Spacer()
                Text(item.lastUsedAt, style: .relative)
                    .font(.caption)
                Text("⌘\(index + 1)")
                    .font(.caption2.monospaced())
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.18), in: Capsule())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(headerColor)

            Group {
                switch item.payload {
                case let .text(text): TextCardContent(text: text)
                case let .url(url): URLCardContent(url: url, previewsEnabled: linkPreviewsEnabled)
                case let .image(metadata): ImageCardContent(metadata: metadata)
                case let .files(files): FilesCardContent(files: files)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.background)

            HStack {
                if let icon = sourceApplicationIcon {
                    SourceApplicationIconView(image: icon, name: item.source.name)
                        .frame(width: 20, height: 20)
                }
                Spacer()
                Image(systemName: "line.3.horizontal")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(.background)
        }
        .frame(width: 238, height: 246)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? Color.accentColor : .white.opacity(0.16), lineWidth: isSelected ? 4 : 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.payload.kindLabel)，来自 \(item.source.name)")
    }

    private var sourceApplicationIcon: NSImage? {
        guard let bundleIdentifier = item.source.bundleIdentifier,
              !bundleIdentifier.isEmpty,
              let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return nil
        }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        return icon.isValid ? icon : nil
    }

    private var headerColor: Color {
        switch item.payload {
        case .text: .green
        case .url: .indigo
        case .image: .blue
        case .files: .blue
        }
    }
}

private struct SourceApplicationIconView: NSViewRepresentable {
    let image: NSImage
    let name: String

    func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView()
        view.imageScaling = .scaleProportionallyUpOrDown
        view.setAccessibilityIdentifier("clipboard-source-icon")
        return view
    }

    func updateNSView(_ view: NSImageView, context: Context) {
        view.image = image
        view.toolTip = name
        view.setAccessibilityLabel(name)
    }
}
