import AppKit
import FinderSync
import SwiftUI

struct MenuBarContentView: View {
    @State private var finderExtensionIsEnabled = FIFinderSyncController.isExtensionEnabled
    @State private var accessibilityIsGranted = FinderRenameController().isAccessibilityGranted

    var body: some View {
        Group {
            Label("MacEase 正在运行", systemImage: "sparkles")

            Divider()

            Button("打开设置…") {
                NSApplication.shared.activate(ignoringOtherApps: true)
                let didOpen = NSApplication.shared.sendAction(
                    Selector(("showSettingsWindow:")),
                    to: nil,
                    from: nil
                )
                if !didOpen {
                    NSApplication.shared.sendAction(
                        Selector(("showPreferencesWindow:")),
                        to: nil,
                        from: nil
                    )
                }
            }

            Button("关于 MacEase") {
                NSApplication.shared.activate(ignoringOtherApps: true)
                NSApplication.shared.orderFrontStandardAboutPanel(nil)
            }

            Button(
                finderExtensionIsEnabled ? "管理 Finder 扩展…" : "启用 Finder 扩展…"
            ) {
                FIFinderSyncController.showExtensionManagementInterface()
            }

            if !accessibilityIsGranted {
                Button("允许 Finder 原地命名…") {
                    accessibilityIsGranted = FinderRenameController()
                        .requestAccessibilityPermission()
                }
            }

            Divider()

            Button("退出 MacEase") {
                NSApplication.shared.terminate(nil)
            }
        }
        .onAppear {
            finderExtensionIsEnabled = FIFinderSyncController.isExtensionEnabled
            accessibilityIsGranted = FinderRenameController().isAccessibilityGranted
        }
    }
}
