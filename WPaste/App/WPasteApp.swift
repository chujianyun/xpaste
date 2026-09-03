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
            Button("打开剪贴板历史") {}
            Divider()
            SettingsLink { Text("设置…") }
            Button("退出 WPaste") { NSApplication.shared.terminate(nil) }
        }

        Settings {
            Form {
                Toggle("音效", isOn: $model.settings.soundEnabled)
                Text("更多设置将在后续增量中提供。")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(width: 480)
        }
    }
}
