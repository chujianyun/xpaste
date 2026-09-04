import SwiftUI

struct PrivacySettingsView: View {
    @Bindable var model: AppModel
    @State private var ignoredBundleIdentifier = ""

    var body: some View {
        Form {
            Section {
                Toggle("在屏幕共享期间隐藏内容", isOn: $model.settings.hideDuringScreenSharing)
                Toggle("生成链接预览", isOn: $model.settings.linkPreviewsEnabled)
                Toggle("忽略敏感内容", isOn: $model.settings.ignoreSensitiveContent)
                Toggle("忽略瞬时内容", isOn: $model.settings.ignoreTransientContent)
            }
            Section("忽略应用程序") {
                ForEach(model.settings.ignoredBundleIdentifiers.sorted(), id: \.self) { bundleID in
                    HStack {
                        Text(bundleID)
                        Spacer()
                        Button { model.settings.ignoredBundleIdentifiers.remove(bundleID) } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.plain)
                    }
                }
                HStack {
                    TextField("应用 Bundle ID", text: $ignoredBundleIdentifier)
                    Button("添加") {
                        let value = ignoredBundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !value.isEmpty else { return }
                        model.settings.ignoredBundleIdentifiers.insert(value)
                        ignoredBundleIdentifier = ""
                    }
                }
                Toggle("退出应用时清空历史", isOn: $model.settings.clearHistoryOnQuit)
                Button("清理预览缓存") { model.clearPreviewCache() }
            }
        }
        .formStyle(.grouped)
    }
}

