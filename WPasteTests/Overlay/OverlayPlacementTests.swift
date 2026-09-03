import CoreGraphics
import Testing
@testable import WPaste

struct OverlayPlacementTests {
    @Test func panelUsesVisibleScreenWidthAndBottomEdge() {
        let visibleFrame = CGRect(x: 100, y: 80, width: 1440, height: 820)
        #expect(OverlayPlacement.frame(in: visibleFrame, height: 332) == CGRect(x: 100, y: 80, width: 1440, height: 332))
    }
}

