import AppKit
import SwiftUI

enum OverlayPlacement {
    static func frame(in visibleFrame: CGRect, height: CGFloat) -> CGRect {
        CGRect(x: visibleFrame.minX, y: visibleFrame.minY, width: visibleFrame.width, height: min(height, visibleFrame.height))
    }
}

@MainActor
final class OverlayWindowController: NSObject, NSWindowDelegate {
    private var panel: KeyablePanel?

    var isVisible: Bool { panel?.isVisible == true }

    func show<Content: View>(hideFromScreenCapture: Bool = false, @ViewBuilder content: () -> Content) {
        let screen = screenAtMouse() ?? NSScreen.main
        guard let screen else { return }
        let panel = panel ?? makePanel()
        panel.sharingType = hideFromScreenCapture ? .none : .readOnly
        panel.contentViewController = NSHostingController(rootView: content())
        panel.setFrame(OverlayPlacement.frame(in: screen.visibleFrame, height: 332), display: true)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.panel = panel
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }

    private func makePanel() -> KeyablePanel {
        let panel = KeyablePanel(
            contentRect: .zero,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.delegate = self
        return panel
    }

    private func screenAtMouse() -> NSScreen? {
        let location = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(location) }
    }
}

private final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
