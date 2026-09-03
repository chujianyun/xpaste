import Foundation

enum HistoryRetention: String, CaseIterable, Codable, Sendable {
    case oneDay
    case sevenDays
    case oneMonth
    case oneYear
    case forever
}

enum DefaultPasteBehavior: String, Codable, Sendable {
    case automatic
    case copyOnly
}

struct AppSettings: Codable, Equatable, Sendable {
    var launchAtLogin: Bool
    var soundEnabled: Bool
    var defaultPasteBehavior: DefaultPasteBehavior
    var defaultPlainText: Bool
    var retention: HistoryRetention
    var hideDuringScreenSharing: Bool
    var linkPreviewsEnabled: Bool
    var ignoreSensitiveContent: Bool
    var ignoreTransientContent: Bool
    var ignoredBundleIdentifiers: Set<String>
    var clearHistoryOnQuit: Bool
    var recordingPaused: Bool

    static let `default` = AppSettings(
        launchAtLogin: false,
        soundEnabled: true,
        defaultPasteBehavior: .automatic,
        defaultPlainText: false,
        retention: .sevenDays,
        hideDuringScreenSharing: true,
        linkPreviewsEnabled: true,
        ignoreSensitiveContent: true,
        ignoreTransientContent: true,
        ignoredBundleIdentifiers: [],
        clearHistoryOnQuit: false,
        recordingPaused: false
    )
}
