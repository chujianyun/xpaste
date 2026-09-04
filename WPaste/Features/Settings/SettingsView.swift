import SwiftUI

private enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "通用"
    case privacy = "隐私"
    case shortcuts = "键盘快捷键"
    var id: Self { self }
}

struct SettingsView: View {
    @Bindable var model: AppModel
    @State private var selection: SettingsSection? = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selection) { section in
                Label(section.rawValue, systemImage: icon(for: section))
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(190)
        } detail: {
            Group {
                switch selection ?? .general {
                case .general: GeneralSettingsView(model: model)
                case .privacy: PrivacySettingsView(model: model)
                case .shortcuts: ShortcutSettingsView(model: model)
                }
            }
            .navigationTitle((selection ?? .general).rawValue)
            .padding(16)
        }
        .frame(width: 716, height: 668)
        .onChange(of: model.settings) { _, _ in model.persistSettings() }
    }

    private func icon(for section: SettingsSection) -> String {
        switch section {
        case .general: "gearshape"
        case .privacy: "hand.raised"
        case .shortcuts: "keyboard"
        }
    }
}

