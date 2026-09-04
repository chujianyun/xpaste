@preconcurrency import ApplicationServices
import Foundation

@MainActor
protocol AccessibilityControlling {
    var isTrusted: Bool { get }
    func requestPermission()
    func sendPasteCommand() -> Bool
}

extension AccessibilityControlling {
    func requestPermission() {}
}

@MainActor
struct SystemAccessibilityClient: AccessibilityControlling {
    var isTrusted: Bool { AXIsProcessTrusted() }

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    func sendPasteCommand() -> Bool {
        guard isTrusted,
              let source = CGEventSource(stateID: .hidSystemState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else { return false }
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }
}
