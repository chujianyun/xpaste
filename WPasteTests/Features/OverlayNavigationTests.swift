import Testing
@testable import WPaste

struct OverlayNavigationTests {
    @Test func selectionWrapsAcrossVisibleItems() {
        var navigation = OverlayNavigation(itemCount: 3)
        navigation.movePrevious()
        #expect(navigation.selectedIndex == 2)
        navigation.moveNext()
        #expect(navigation.selectedIndex == 0)
        navigation.moveNext()
        #expect(navigation.selectedIndex == 1)
    }

    @Test func numericSelectionUsesOneBasedPositionAndBounds() {
        var navigation = OverlayNavigation(itemCount: 4)
        #expect(navigation.selectQuickPosition(3) == 2)
        #expect(navigation.selectedIndex == 2)
        #expect(navigation.selectQuickPosition(9) == nil)
        #expect(navigation.selectedIndex == 2)
    }

    @Test func updatingToEmptyItemsClearsSelection() {
        var navigation = OverlayNavigation(itemCount: 2)
        navigation.updateItemCount(0)
        #expect(navigation.selectedIndex == nil)
    }
}

