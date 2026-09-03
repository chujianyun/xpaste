import SwiftUI

struct ClipboardCardView: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool

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
                case let .url(url): URLCardContent(url: url)
                case let .image(metadata): ImageCardContent(metadata: metadata)
                case let .files(files): FilesCardContent(files: files)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.background)

            HStack {
                Text(item.source.name)
                    .lineLimit(1)
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

    private var headerColor: Color {
        switch item.payload {
        case .text: .green
        case .url: .indigo
        case .image: .blue
        case .files: .blue
        }
    }
}

