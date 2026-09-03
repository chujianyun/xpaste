import Observation

@MainActor
@Observable
final class AppModel {
    var settings: AppSettings

    init(settings: AppSettings = .default) {
        self.settings = settings
    }
}

