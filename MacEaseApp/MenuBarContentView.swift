import AppKit
import FinderSync
import SwiftUI

struct MenuBarContentView: View {
    @State private var finderExtensionIsEnabled = FIFinderSyncController.isExtensionEnabled
    @State private var accessibilityIsGranted = FinderRenameController().isAccessibilityGranted

    var body: some View {
        Group {
            Label(
                AppLocalization.string(
                    "menu.running",
                    fallback: "MacEase is running"
                ),
                systemImage: "sparkles"
            )

            Divider()

            Button(AppLocalization.string(
                "menu.openSettings",
                fallback: "Open Settings…"
            )) {
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

            Button(AppLocalization.string(
                "menu.about",
                fallback: "About MacEase"
            )) {
                NSApplication.shared.activate(ignoringOtherApps: true)
                NSApplication.shared.orderFrontStandardAboutPanel(nil)
            }

            Button(
                finderExtensionIsEnabled
                    ? AppLocalization.string(
                        "menu.manageFinderExtension",
                        fallback: "Manage Finder Extension…"
                    )
                    : AppLocalization.string(
                        "menu.enableFinderExtension",
                        fallback: "Enable Finder Extension…"
                    )
            ) {
                FIFinderSyncController.showExtensionManagementInterface()
            }

            if !accessibilityIsGranted {
                Button(AppLocalization.string(
                    "menu.allowFinderRename",
                    fallback: "Allow In-place Finder Renaming…"
                )) {
                    accessibilityIsGranted = FinderRenameController()
                        .requestAccessibilityPermission()
                }
            }

            Divider()

            Button(AppLocalization.string(
                "menu.quit",
                fallback: "Quit MacEase"
            )) {
                NSApplication.shared.terminate(nil)
            }
        }
        .onAppear {
            finderExtensionIsEnabled = FIFinderSyncController.isExtensionEnabled
            accessibilityIsGranted = FinderRenameController().isAccessibilityGranted
        }
    }
}
