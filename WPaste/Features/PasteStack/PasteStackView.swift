import SwiftUI

struct PasteStackView: View {
    let store: PasteStackStore
    let onPasteNext: (ClipboardItem) -> Void
    let onClose: () -> Void
    @State private var items: [ClipboardItem] = []

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Paste Stack", systemImage: "square.stack.3d.up.fill")
                    .font(.headline)
                Text("剩余 \(items.count) 项").foregroundStyle(.secondary)
                Spacer()
                Button("清空", role: .destructive) { try? store.clear(); reload() }
                Button("关闭") { onClose() }
            }
            .padding(.horizontal, 20)
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        ClipboardCardView(item: item, index: index, isSelected: index == 0)
                            .contextMenu {
                                Button("粘贴下一项") { onPasteNext(item) }
                                Button("移除", role: .destructive) { try? store.remove(item.id); reload() }
                            }
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .onAppear(perform: reload)
        .onKeyPress(.return) {
            if let first = items.first { onPasteNext(first) }
            return .handled
        }
        .onKeyPress(.escape) { onClose(); return .handled }
    }

    private func reload() {
        items = (try? store.items()) ?? []
    }
}

