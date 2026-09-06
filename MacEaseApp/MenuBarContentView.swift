import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @AppStorage(ScrollDirectionPreferences.isEnabledKey)
    private var scrollDirectionIsEnabled = false
    @AppStorage(DockShortcutPreferences.isEnabledKey)
    private var dockShortcutsIsEnabled = false

    var body: some View {
        Group {
            Toggle(
                AppLocalization.string("menu.scrollDirection", fallback: "Scroll Direction Control"),
                isOn: $scrollDirectionIsEnabled
            )
            Toggle(
                AppLocalization.string("menu.dockShortcuts", fallback: "Dock App Shortcuts"),
                isOn: $dockShortcutsIsEnabled
            )

            Divider()

            Button(AppLocalization.string("menu.openSettings", fallback: "Open Settings…")) {
                SettingsWindowPresenter.open()
            }
            .keyboardShortcut(",", modifiers: .command)

            Button(AppLocalization.string("menu.quit", fallback: "Quit MacEase")) {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .onAppear {
            ScrollDirectionController.shared.reloadPreferences()
            DockShortcutController.shared.reloadPreferences()
        }
        .onChange(of: scrollDirectionIsEnabled) { _ in
            ScrollDirectionController.shared.reloadPreferences()
        }
        .onChange(of: dockShortcutsIsEnabled) { _ in
            DockShortcutController.shared.reloadPreferences()
        }
    }
}
