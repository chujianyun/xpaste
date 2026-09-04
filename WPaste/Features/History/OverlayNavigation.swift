import Foundation

struct OverlayNavigation: Equatable, Sendable {
    private(set) var selectedIndex: Int?
    private var itemCount: Int

    init(itemCount: Int) {
        self.itemCount = max(0, itemCount)
        selectedIndex = itemCount > 0 ? 0 : nil
    }

    mutating func updateItemCount(_ count: Int) {
        itemCount = max(0, count)
        guard itemCount > 0 else {
            selectedIndex = nil
            return
        }
        selectedIndex = min(selectedIndex ?? 0, itemCount - 1)
    }

    mutating func moveNext() {
        guard itemCount > 0 else { return }
        selectedIndex = ((selectedIndex ?? -1) + 1) % itemCount
    }

    mutating func movePrevious() {
        guard itemCount > 0 else { return }
        selectedIndex = ((selectedIndex ?? 0) - 1 + itemCount) % itemCount
    }

    @discardableResult
    mutating func selectQuickPosition(_ position: Int) -> Int? {
        let index = position - 1
        guard index >= 0, index < itemCount else { return nil }
        selectedIndex = index
        return index
    }

    mutating func select(_ index: Int) {
        guard index >= 0, index < itemCount else { return }
        selectedIndex = index
    }
}

