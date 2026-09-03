import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowController: NSObject, NSWindowDelegate {
    private let stateStore: OnboardingStateStore
    private var window: NSWindow?

    init(stateStore: OnboardingStateStore = .init()) {
        self.stateStore = stateStore
    }

    func showIfNeeded() {
        guard stateStore.isRequired else { return }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "欢迎使用 WPaste"
        window.center()
        window.delegate = self
        window.contentViewController = NSHostingController(rootView: OnboardingView { [weak self] in
            self?.stateStore.acknowledge()
            self?.window?.close()
        })
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}

