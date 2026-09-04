import ServiceManagement

@MainActor
struct LoginItemClient {
    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    var isEnabled: Bool { SMAppService.mainApp.status == .enabled }
}

