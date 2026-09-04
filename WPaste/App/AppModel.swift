import AppKit
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
    private let shortcutPersistence = ShortcutPersistence()
    private let frontmostApplication = FrontmostApplicationClient()
    private let settingsPersistence = SettingsPersistence()
    private let loginItem = LoginItemClient()
    private let linkPreviewService = LinkPreviewService()
    private let onboardingWindow = OnboardingWindowController()
    private var pasteTarget: ApplicationTargeting?
    private var maintenanceTask: Task<Void, Never>?

    init(settings: AppSettings? = nil) {
        self.settings = settings ?? SettingsPersistence().load()
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
        startMaintenance()
        onboardingWindow.showIfNeeded()
        for (action, shortcut) in shortcutPersistence.load() {
            _ = shortcutManager.update(action, to: shortcut)
        }
        shortcutManager.onAction = { [weak self] action in
            switch action {
            case .showHistory: self?.showHistory()
            default: break
            }
        }
    }

    func start() {
        monitor?.start()
    }

    func stop() {
        monitor?.stop()
        maintenanceTask?.cancel()
        maintenanceTask = nil
        if settings.clearHistoryOnQuit { clearHistory() }
    }

    func persistSettings() {
        do {
            try settingsPersistence.save(settings)
            if loginItem.isEnabled != settings.launchAtLogin {
                try loginItem.setEnabled(settings.launchAtLogin)
            }
        } catch {
            userNotice = "设置保存失败：\(error.localizedDescription)"
        }
    }

    func clearHistory() {
        do { try repository?.clear() } catch { userNotice = "历史删除失败：\(error.localizedDescription)" }
    }

    func clearPreviewCache() {
        linkPreviewService.clearCache()
        userNotice = "预览缓存已清理"
    }

    func resetShortcuts() {
        shortcutManager.resetDefaults()
        try? shortcutPersistence.save(shortcutManager.shortcuts)
    }

    func updateShortcut(_ action: ShortcutAction, to shortcut: Shortcut) {
        switch shortcutManager.update(action, to: shortcut) {
        case .success:
            try? shortcutPersistence.save(shortcutManager.shortcuts)
            userNotice = nil
        case let .internalConflict(conflict):
            userNotice = "快捷键与 \(conflict.rawValue) 冲突"
        case .registrationFailed:
            userNotice = "系统无法注册该快捷键，已保留原设置"
        }
    }

    func shortcutDescription(_ action: ShortcutAction) -> String {
        guard let shortcut = shortcutManager.shortcuts[action] else { return "—" }
        var result = ""
        if shortcut.modifiers.contains(.control) { result += "⌃" }
        if shortcut.modifiers.contains(.option) { result += "⌥" }
        if shortcut.modifiers.contains(.shift) { result += "⇧" }
        if shortcut.modifiers.contains(.command) { result += "⌘" }
        result += keyName(shortcut.keyCode)
        return result
    }

    private func keyName(_ keyCode: UInt32) -> String {
        switch keyCode {
        case 8: "C"
        case 9: "V"
        case 18: "1…9"
        case 56: "Shift"
        case 123: "←"
        case 124: "→"
        default: "\(keyCode)"
        }
    }

    func showHistory() {
        guard let repository else {
            userNotice = "无法打开历史数据库"
            return
        }
        pasteTarget = frontmostApplication.capture()
        let history = HistoryStore(repository: repository)
        let pinboards = PinboardStore(repository: repository)
        let linkPreviewsEnabled = settings.linkPreviewsEnabled
        overlay.show(hideFromScreenCapture: settings.hideDuringScreenSharing) { [weak self] in
            HistoryOverlayView(
                history: history,
                pinboards: pinboards,
                linkPreviewsEnabled: linkPreviewsEnabled,
                onPaste: { item, plainText in self?.paste(item, plainText: plainText) },
                onClose: { self?.overlay.hide() }
            )
        }
    }

    private func paste(_ item: ClipboardItem, plainText: Bool) {
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
        if settings.soundEnabled, result == .pasted || result == .copied {
            NSSound(named: "Tink")?.play()
        }
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

    private func startMaintenance() {
        _ = try? repository?.cleanExpired(retention: settings.retention)
        maintenanceTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3_600))
                guard let self else { return }
                _ = try? repository?.cleanExpired(retention: settings.retention)
            }
        }
    }
}
