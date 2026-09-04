import SwiftUI

struct ShortcutSettingsView: View {
    @Bindable var model: AppModel

    var body: some View {
        Form {
            Section {
                shortcutRow("启动 WPaste", action: .showHistory)
            }
            Section {
                shortcutRow("显示下一个 Pinboard", action: .nextPinboard)
                shortcutRow("显示上一个 Pinboard", action: .previousPinboard)
            }
            Section {
                shortcutRow("快速粘贴", action: .quickPaste)
                shortcutRow("纯文本模式", action: .plainTextMode)
            }
            Button("将快捷方式重置为默认…") { model.resetShortcuts() }
        }
        .formStyle(.grouped)
    }

    private func shortcutRow(_ title: String, action: ShortcutAction) -> some View {
        HStack {
            Text(title)
            Spacer()
            ShortcutRecorderButton(current: model.shortcutDescription(action)) { shortcut in
                model.updateShortcut(action, to: shortcut)
            }
        }
    }
}
