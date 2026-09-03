import Foundation

struct ShortcutPersistence {
    private struct Entry: Codable {
        let action: ShortcutAction
        let shortcut: Shortcut
    }

    private let defaults: UserDefaults
    private let key = "WPaste.Shortcuts.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [ShortcutAction: Shortcut] {
        guard let data = defaults.data(forKey: key),
              let entries = try? JSONDecoder().decode([Entry].self, from: data) else { return [:] }
        return Dictionary(uniqueKeysWithValues: entries.map { ($0.action, $0.shortcut) })
    }

    func save(_ shortcuts: [ShortcutAction: Shortcut]) throws {
        let entries = shortcuts.map { Entry(action: $0.key, shortcut: $0.value) }
            .sorted { $0.action.rawValue < $1.action.rawValue }
        defaults.set(try JSONEncoder().encode(entries), forKey: key)
    }
}

