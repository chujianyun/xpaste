import SwiftUI

struct OnboardingStateStore {
    private let defaults: UserDefaults
    private let key = "WPaste.OnboardingAcknowledged.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isRequired: Bool { !defaults.bool(forKey: key) }

    func acknowledge() {
        defaults.set(true, forKey: key)
    }
}

struct OnboardingView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "clipboard.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue)
            Text("欢迎使用 WPaste")
                .font(.largeTitle.bold())
            Text("WPaste 会读取系统剪贴板，并将历史记录仅保存在这台 Mac 上。默认保留 7 天；你可以随时暂停记录或清空历史。")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 440)
            Text("只有启用自动粘贴时才需要辅助功能权限。拒绝权限不会影响历史、搜索和复制。")
                .font(.callout)
                .multilineTextAlignment(.center)
            Button("开始使用") { onContinue() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(42)
        .frame(width: 560, height: 420)
    }
}

