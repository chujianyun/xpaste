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
        .frame(width: 900, height: 500)
        .background(SettingsWindowAppearance())
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

private struct SettingsWindowAppearance: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowView { WindowView() }

    func updateNSView(_ nsView: WindowView, context: Context) {
        nsView.applyAppearance()
    }

    final class WindowView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            applyAppearance()
        }

        func applyAppearance() {
            guard let window else { return }
            // Blend the native traffic lights into the sidebar's titlebar area.
            window.titlebarAppearsTransparent = true
            window.titlebarSeparatorStyle = .none
            window.toolbarStyle = .unified
        }
    }
}
