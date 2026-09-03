import SwiftUI

struct HistoryOverlayView: View {
    @Bindable var history: HistoryStore
    @Bindable var pinboards: PinboardStore
    let stack: PasteStackStore
    let onPaste: (ClipboardItem, Bool) -> Void
    let onClose: () -> Void

    @State private var navigation = OverlayNavigation(itemCount: 0)
    @State private var selectedPinboardID: UUID?
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 10) {
            navigationBar
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 18) {
                        ForEach(Array(displayedItems.enumerated()), id: \.element.id) { index, item in
                            ClipboardCardView(item: item, index: index, isSelected: navigation.selectedIndex == index)
                                .id(item.id)
                                .onTapGesture { navigation.select(index); onPaste(item, false) }
                                .contextMenu { contextMenu(for: item) }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .scrollIndicators(.hidden)
                .onChange(of: navigation.selectedIndex) { _, index in
                    guard let index, displayedItems.indices.contains(index) else { return }
                    withAnimation { proxy.scrollTo(displayedItems[index].id, anchor: .center) }
                }
            }
        }
        .padding(.vertical, 12)
        .frame(minWidth: 760, minHeight: 300)
        .background(.ultraThinMaterial)
        .onAppear { try? history.reload(); syncCount() }
        .onChange(of: history.query) { _, _ in syncCount() }
        .onChange(of: selectedPinboardID) { _, _ in syncCount() }
        .onKeyPress(.leftArrow) { navigation.movePrevious(); return .handled }
        .onKeyPress(.rightArrow) { navigation.moveNext(); return .handled }
        .onKeyPress(.return) { pasteSelection(plainText: false); return .handled }
        .onKeyPress(.escape) { onClose(); return .handled }
    }

    private var navigationBar: some View {
        HStack(spacing: 14) {
            TextField("搜索", text: $history.query)
                .textFieldStyle(.roundedBorder)
                .focused($searchFocused)
                .frame(width: 220)
            boardButton(title: "剪贴板历史", id: nil)
            ForEach(pinboards.pinboards) { board in boardButton(title: board.name, id: board.id) }
            Button { _ = try? pinboards.create(name: "新 Pinboard") } label: { Image(systemName: "plus") }
                .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func boardButton(title: String, id: UUID?) -> some View {
        Button(title) { selectedPinboardID = id }
            .buttonStyle(.plain)
            .fontWeight(selectedPinboardID == id ? .semibold : .regular)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(selectedPinboardID == id ? Color.primary.opacity(0.1) : .clear, in: Capsule())
    }

    @ViewBuilder
    private func contextMenu(for item: ClipboardItem) -> some View {
        Button("复制") { onPaste(item, false) }
        Button("纯文本粘贴") { onPaste(item, true) }
        Menu("收藏到 Pinboard") {
            ForEach(pinboards.pinboards) { board in
                Button(board.name) { try? pinboards.add(itemID: item.id, to: board.id) }
            }
        }
        Button("加入 Paste Stack") { try? stack.add(item.id) }
        Divider()
        Button("删除", role: .destructive) { try? history.delete(id: item.id); syncCount() }
    }

    private var displayedItems: [ClipboardItem] {
        guard let selectedPinboardID,
              let ids = try? pinboards.itemIDs(in: selectedPinboardID) else { return history.filteredItems }
        let set = Set(ids)
        return history.filteredItems.filter { set.contains($0.id) }
    }

    private func syncCount() {
        navigation.updateItemCount(displayedItems.count)
    }

    private func pasteSelection(plainText: Bool) {
        guard let index = navigation.selectedIndex, displayedItems.indices.contains(index) else { return }
        onPaste(displayedItems[index], plainText)
    }
}

