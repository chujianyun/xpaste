import SwiftUI

struct GeneralSettingsView: View {
    @Bindable var model: AppModel
    @State private var confirmClearHistory = false

    var body: some View {
        Form {
            Section {
                Toggle("登录时打开", isOn: $model.settings.launchAtLogin)
                Toggle("音效", isOn: $model.settings.soundEnabled)
            }
            Section("粘贴项目") {
                Picker("默认行为", selection: $model.settings.defaultPasteBehavior) {
                    Text("自动粘贴到当前应用").tag(DefaultPasteBehavior.automatic)
                    Text("只复制到剪贴板").tag(DefaultPasteBehavior.copyOnly)
                }
                .pickerStyle(.radioGroup)
                Toggle("始终以纯文本粘贴", isOn: $model.settings.defaultPlainText)
            }
            Section("保留历史") {
                Picker("保留期限", selection: $model.settings.retention) {
                    Text("1 天").tag(HistoryRetention.oneDay)
                    Text("1 周").tag(HistoryRetention.sevenDays)
                    Text("1 个月").tag(HistoryRetention.oneMonth)
                    Text("1 年").tag(HistoryRetention.oneYear)
                    Text("永久").tag(HistoryRetention.forever)
                }
                Button("删除历史…", role: .destructive) { confirmClearHistory = true }
            }
        }
        .formStyle(.grouped)
        .alert("删除全部剪贴板历史？", isPresented: $confirmClearHistory) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) { model.clearHistory() }
        }
    }
}

