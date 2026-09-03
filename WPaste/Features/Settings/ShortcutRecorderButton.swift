import SwiftUI

struct ShortcutRecorderButton: View {
    let current: String
    let onRecorded: (Shortcut) -> Void
    @State private var isRecording = false
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(isRecording ? "请按快捷键…" : current) {
            isRecording = true
            isFocused = true
        }
        .font(.body.monospaced())
        .buttonStyle(.bordered)
        .focused($isFocused)
        .onKeyPress(phases: .down) { press in
            guard isRecording else { return .ignored }
            if press.key == .escape {
                isRecording = false
                return .handled
            }
            guard let keyCode = ShortcutKeyMap.keyCode(for: press), !press.modifiers.isEmpty else {
                return .handled
            }
            onRecorded(Shortcut(keyCode: keyCode, modifiers: ShortcutModifiers(press.modifiers)))
            isRecording = false
            return .handled
        }
        .accessibilityLabel(isRecording ? "正在录制快捷键" : "当前快捷键 \(current)")
    }
}

private enum ShortcutKeyMap {
    static func keyCode(for press: KeyPress) -> UInt32? {
        if press.key == .leftArrow { return 123 }
        if press.key == .rightArrow { return 124 }
        let character = press.characters.lowercased()
        return keyCodes[character]
    }

    private static let keyCodes: [String: UInt32] = [
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7,
        "c": 8, "v": 9, "b": 11, "q": 12, "w": 13, "e": 14, "r": 15,
        "y": 16, "t": 17, "1": 18, "2": 19, "3": 20, "4": 21, "6": 22,
        "5": 23, "=": 24, "9": 25, "7": 26, "-": 27, "8": 28, "0": 29,
        "]": 30, "o": 31, "u": 32, "[": 33, "i": 34, "p": 35, "l": 37,
        "j": 38, "'": 39, "k": 40, ";": 41, "\\": 42, ",": 43, "/": 44,
        "n": 45, "m": 46, ".": 47
    ]
}

private extension ShortcutModifiers {
    init(_ modifiers: EventModifiers) {
        var result: ShortcutModifiers = []
        if modifiers.contains(.command) { result.insert(.command) }
        if modifiers.contains(.option) { result.insert(.option) }
        if modifiers.contains(.control) { result.insert(.control) }
        if modifiers.contains(.shift) { result.insert(.shift) }
        self = result
    }
}

