import AppKit
import SwiftUI

@main
struct WPasteApp: App {
    @State private var model = AppModel()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra("WPaste", systemImage: "clipboard") {
            Button("打开剪贴板历史") { model.showHistory() }
                .keyboardShortcut("v", modifiers: [.command, .shift])
            Toggle("暂停记录", isOn: $model.settings.recordingPaused)
            if let notice = model.userNotice {
                Divider()
                Text(notice)
                    .font(.caption)
            }
            Divider()
            Button("设置…") { model.showSettings() }
                .keyboardShortcut(",", modifiers: .command)
            Button("退出 WPaste") {
                model.stop()
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
