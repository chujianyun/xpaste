import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    var settings: AppSettings
    var userNotice: String?
    let repository: HistoryRepository?
    private(set) var monitor: ClipboardMonitor?
    private let overlay = OverlayWindowController()
    private let shortcutManager = ShortcutManager()
    private let frontmostApplication = FrontmostApplicationClient()
    private var pasteTarget: ApplicationTargeting?

    init(settings: AppSettings = .default) {
        self.settings = settings
        repository = try? HistoryRepository()
        monitor = nil
        if let repository {
            monitor = ClipboardMonitor(
                pasteboard: SystemPasteboardClient(),
                repository: repository,
                settings: { [weak self] in self?.settings ?? .default }
            )
        }
        monitor?.start()
        shortcutManager.onAction = { [weak self] action in
            switch action {
            case .showHistory: self?.showHistory()
            case .showPasteStack: self?.showPasteStack()
            default: break
            }
        }
    }

    func start() {
        monitor?.start()
    }

    func stop() {
        monitor?.stop()
    }

    func showHistory() {
        guard let repository else {
            userNotice = "无法打开历史数据库"
            return
        }
        pasteTarget = frontmostApplication.capture()
        let history = HistoryStore(repository: repository)
        let pinboards = PinboardStore(repository: repository)
        let stack = PasteStackStore(repository: repository)
        overlay.show { [weak self] in
            HistoryOverlayView(
                history: history,
                pinboards: pinboards,
                stack: stack,
                onPaste: { item, plainText in self?.paste(item, plainText: plainText, stack: nil) },
                onClose: { self?.overlay.hide() }
            )
        }
    }

    func showPasteStack() {
        guard let repository else { return }
        pasteTarget = frontmostApplication.capture()
        let stack = PasteStackStore(repository: repository)
        overlay.show { [weak self] in
            PasteStackView(
                store: stack,
                onPasteNext: { item in self?.paste(item, plainText: false, stack: stack) },
                onClose: { self?.overlay.hide() }
            )
        }
    }

    private func paste(_ item: ClipboardItem, plainText: Bool, stack: PasteStackStore?) {
        let coordinator = PasteCoordinator(
            pasteboard: SystemPasteboardWriter(),
            accessibility: SystemAccessibilityClient(),
            closeOverlay: { [weak self] in self?.overlay.hide() },
            suppressWrite: { [weak self] fingerprint, date in
                self?.monitor?.suppressNextWrite(fingerprint: fingerprint, until: date)
            }
        )
        let mode: PasteMode = settings.defaultPasteBehavior == .automatic
            ? .automatic(plainText: plainText || settings.defaultPlainText)
            : .copyOnly(plainText: plainText || settings.defaultPlainText)
        let result = coordinator.paste(item: item, mode: mode, target: pasteTarget)
        try? stack?.completeFirst(successfullyPasted: result == .pasted)
        switch result {
        case .pasted: userNotice = nil
        case .copied: userNotice = "已复制到剪贴板"
        case let .copiedOnly(reason): userNotice = fallbackMessage(for: reason)
        case .unavailable: userNotice = "内容不可用，未更改剪贴板"
        }
    }

    private func fallbackMessage(for reason: PasteFallbackReason) -> String {
        switch reason {
        case .accessibilityPermissionMissing: "需要辅助功能权限；内容已复制到剪贴板"
        case .targetUnavailable: "原应用已退出；内容已复制到剪贴板"
        case .activationFailed: "无法恢复原应用；内容已复制到剪贴板"
        case .keyEventFailed: "无法发送粘贴按键；内容已复制到剪贴板"
        }
    }
}
