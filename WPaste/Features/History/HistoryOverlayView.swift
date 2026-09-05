import SwiftUI

struct HistoryOverlayView: View {
    @Bindable var history: HistoryStore
    @Bindable var pinboards: PinboardStore
    var linkPreviewsEnabled = true
    let onPaste: (ClipboardItem, Bool) -> Void
    let onClose: () -> Void

    @State private var navigation = OverlayNavigation(itemCount: 0)
    @State private var selectedPinboardID: UUID?
    @State private var showingNewPinboard = false
    @State private var newPinboardName = ""
    @State private var boardBeingRenamed: Pinboard?
    @State private var renamedBoardName = ""
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 10) {
            navigationBar
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 18) {
                        ForEach(Array(displayedItems.enumerated()), id: \.element.id) { index, item in
                            ClipboardCardView(
                                item: item,
                                index: index,
                                isSelected: navigation.selectedIndex == index,
                                linkPreviewsEnabled: linkPreviewsEnabled
                            )
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
        .onKeyPress(phases: .down) { press in
            guard press.modifiers.contains(.command), let position = Int(press.characters),
                  let index = navigation.selectQuickPosition(position), displayedItems.indices.contains(index) else {
                return .ignored
            }
            onPaste(displayedItems[index], false)
            return .handled
        }
        .alert("新建 Pinboard", isPresented: $showingNewPinboard) {
            TextField("名称", text: $newPinboardName)
            Button("取消", role: .cancel) {}
            Button("创建") {
                _ = try? pinboards.create(name: newPinboardName)
                newPinboardName = ""
            }
        }
        .alert("重命名 Pinboard", isPresented: Binding(
            get: { boardBeingRenamed != nil },
            set: { if !$0 { boardBeingRenamed = nil } }
        )) {
            TextField("名称", text: $renamedBoardName)
            Button("取消", role: .cancel) { boardBeingRenamed = nil }
            Button("保存") {
                if let board = boardBeingRenamed { try? pinboards.rename(id: board.id, name: renamedBoardName) }
                boardBeingRenamed = nil
            }
        }
    }

    private var navigationBar: some View {
        HStack(spacing: 14) {
            HistorySearchField(text: $history.query)
                .focused($searchFocused)
                .frame(width: 220)
            boardButton(title: "剪贴板历史", id: nil)
            ForEach(pinboards.pinboards) { board in boardButton(title: board.name, id: board.id) }
            Button { showingNewPinboard = true } label: { Image(systemName: "plus") }
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
            .contextMenu {
                if let id, let index = pinboards.pinboards.firstIndex(where: { $0.id == id }) {
                    Button("重命名") {
                        boardBeingRenamed = pinboards.pinboards[index]
                        renamedBoardName = title
                    }
                    Button("向左移动") { try? pinboards.move(id: id, to: max(0, index - 1)) }
                        .disabled(index == 0)
                    Button("向右移动") { try? pinboards.move(id: id, to: min(pinboards.pinboards.count - 1, index + 1)) }
                        .disabled(index == pinboards.pinboards.count - 1)
                    Divider()
                    Button("删除 Pinboard", role: .destructive) {
                        try? pinboards.delete(id: id)
                        selectedPinboardID = nil
                    }
                }
            }
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

private struct HistorySearchField: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSSearchField {
        let field = NSSearchField()
        field.placeholderString = "搜索"
        field.setAccessibilityLabel("搜索")
        field.sendsSearchStringImmediately = true
        field.delegate = context.coordinator
        field.target = context.coordinator
        field.action = #selector(Coordinator.searchChanged(_:))
        return field
    }

    func updateNSView(_ field: NSSearchField, context: Context) {
        context.coordinator.text = $text
        if field.stringValue != text { field.stringValue = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    @MainActor
    final class Coordinator: NSObject, NSSearchFieldDelegate {
        var text: Binding<String>

        init(text: Binding<String>) { self.text = text }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSSearchField else { return }
            searchChanged(field)
        }

        @objc func searchChanged(_ field: NSSearchField) {
            text.wrappedValue = field.stringValue
        }
    }
}
