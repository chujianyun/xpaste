import AppKit

@MainActor
protocol ApplicationTargeting: AnyObject {
    var isRunning: Bool { get }
    func activate() -> Bool
}

@MainActor
final class RunningApplicationTarget: ApplicationTargeting {
    private weak var application: NSRunningApplication?

    init(application: NSRunningApplication) {
        self.application = application
    }

    var isRunning: Bool { application?.isTerminated == false }

    func activate() -> Bool {
        application?.activate(options: [.activateAllWindows]) ?? false
    }
}

@MainActor
struct FrontmostApplicationClient {
    func capture() -> ApplicationTargeting? {
        guard let application = NSWorkspace.shared.frontmostApplication else { return nil }
        return RunningApplicationTarget(application: application)
    }
}

