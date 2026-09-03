import Observation

@MainActor
@Observable
final class AppModel {
    var settings: AppSettings
    let repository: HistoryRepository?
    private(set) var monitor: ClipboardMonitor?

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
    }

    func start() {
        monitor?.start()
    }

    func stop() {
        monitor?.stop()
    }
}
