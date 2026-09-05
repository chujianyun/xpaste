import AppKit
import Testing
@testable import WPaste

struct OverlayPlacementTests {
    @Test @MainActor func repeatedHistoryShortcutTogglesWindowVisibility() throws {
        let notificationCenter = NotificationCenter()
        let model = AppModel(settings: .default, shortcutManager: ShortcutManager(notificationCenter: notificationCenter))
        defer { model.stop() }
        let existingWindows = Set(NSApp.windows.map(ObjectIdentifier.init))
        let actionID = UInt32(try #require(ShortcutAction.allCases.firstIndex(of: .showHistory))) + 1
        func pressShortcut() {
            notificationCenter.post(name: .init("WPasteShortcutPressed"), object: actionID)
        }

        pressShortcut()
        let panel = try #require(NSApp.windows.first {
            !existingWindows.contains(ObjectIdentifier($0)) && $0 is NSPanel && $0.isVisible
        })
        defer { panel.orderOut(nil) }
        #expect(panel.isVisible)

        pressShortcut()
        #expect(!panel.isVisible)

        pressShortcut()
        #expect(panel.isVisible)

        panel.orderOut(nil)
        pressShortcut()
        #expect(panel.isVisible)
    }

    @Test func panelUsesVisibleScreenWidthAndBottomEdge() {
        let visibleFrame = CGRect(x: 100, y: 80, width: 1440, height: 820)
        #expect(OverlayPlacement.frame(in: visibleFrame, height: 332) == CGRect(x: 100, y: 80, width: 1440, height: 332))
    }
}
