import AppKit

@MainActor
protocol ApplicationTargeting: AnyObject {
    var isRunning: Bool { get }
    func activate() -> Bool
}

@MainActor
final class RunningApplicationTarget: ApplicationTargeting {
    // The workspace can release its wrapper after the history panel takes focus.
    // Retain it until pasting finishes; isTerminated still tracks a real app exit.
    private let application: NSRunningApplication

    init(application: NSRunningApplication) {
        self.application = application
    }

    var isRunning: Bool { !application.isTerminated }

    func activate() -> Bool {
        application.activate(options: [.activateAllWindows])
    }
}

@MainActor
struct FrontmostApplicationClient {
    func capture() -> ApplicationTargeting? {
        guard let application = NSWorkspace.shared.frontmostApplication else { return nil }
        return RunningApplicationTarget(application: application)
    }
}
