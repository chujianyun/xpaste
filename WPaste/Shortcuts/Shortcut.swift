import Foundation

struct ShortcutModifiers: Codable, OptionSet, Hashable, Sendable {
    let rawValue: UInt32

    static let command = ShortcutModifiers(rawValue: 1 << 0)
    static let option = ShortcutModifiers(rawValue: 1 << 1)
    static let control = ShortcutModifiers(rawValue: 1 << 2)
    static let shift = ShortcutModifiers(rawValue: 1 << 3)
}

struct Shortcut: Codable, Hashable, Sendable {
    let keyCode: UInt32
    let modifiers: ShortcutModifiers
}

enum ShortcutAction: String, CaseIterable, Codable, Hashable, Sendable {
    case showHistory
    case nextPinboard
    case previousPinboard
    case quickPaste
    case plainTextMode
}

enum ShortcutUpdateResult: Equatable {
    case success
    case internalConflict(ShortcutAction)
    case registrationFailed
}
