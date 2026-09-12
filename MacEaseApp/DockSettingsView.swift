import AppKit
import SwiftUI

struct DockSettingsView: View {
    @ObservedObject private var controller = DockShortcutController.shared
    @AppStorage(DockShortcutPreferences.isEnabledKey) private var isEnabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsPageHeader(
                title: SettingsPage.dock.title,
                subtitle: AppLocalization.string("settings.dockShortcutsDescription", fallback: "⌘1 opens Finder. Starting at ⌘2, open pinned Dock apps in order, skipping Apps."),
                isEnabled: $isEnabled,
                toggleLabel: AppLocalization.string("settings.enableDockShortcuts", fallback: "Enable Dock app shortcuts")
            )

            if isEnabled && (controller.failedToStart || !controller.unavailablePositions.isEmpty) {
                SettingsNotice(message: AppLocalization.string("settings.dockShortcutsConflict", fallback: "Some shortcuts are unavailable. Quit Snap or another app using them; MacEase retries automatically."))
            }
            if isEnabled, let error = controller.launchError {
                SettingsNotice(message: AppLocalization.string("settings.dockLaunchError", fallback: "Unable to open app: ") + error)
            }

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(AppLocalization.string("settings.currentShortcuts", fallback: "Current shortcuts"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SettingsGroup {
                        ForEach(controller.shortcuts) { shortcut in
                            if shortcut.position > 1 { Divider() }
                            HStack(spacing: 10) {
                                Image(nsImage: NSWorkspace.shared.icon(forFile: shortcut.application.url.path))
                                    .resizable()
                                    .frame(width: 22, height: 22)
                                    .accessibilityHidden(true)
                                Text(shortcut.application.name)
                                    .lineLimit(1)
                                    .help(shortcut.application.name)
                                Spacer(minLength: 8)
                                if isEnabled && controller.unavailablePositions.contains(shortcut.position) {
                                    Text(AppLocalization.string("settings.dockShortcutUnavailable", fallback: "Unavailable"))
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                                Text(shortcut.label)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    Text(AppLocalization.string("settings.dockOrderHint", fallback: "⌘1 always opens Finder · Apps is skipped"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.5)

            DisclosureGroup(AppLocalization.string("settings.dockHelp", fallback: "Shortcut rules")) {
                Text(AppLocalization.string("settings.dockShortcutsHint", fallback: "⌘1 always opens Finder. ⌘2–⌘9 and ⌘0 follow the next nine pinned apps. Apps, recent apps, folders and spacers are skipped. Assigned shortcuts replace the current app’s Command + number actions until this feature is turned off."))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            }
            .font(.callout)
        }
    }
}
