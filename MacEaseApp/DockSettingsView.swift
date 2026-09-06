import AppKit
import SwiftUI

struct DockSettingsView: View {
    @ObservedObject private var controller = DockShortcutController.shared
    @AppStorage(DockShortcutPreferences.isEnabledKey) private var isEnabled = false
    @AppStorage(DockShortcutPreferences.includesFinderKey) private var includesFinder = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsPageHeader(
                title: SettingsPage.dock.title,
                subtitle: AppLocalization.string("settings.dockShortcutsDescription", fallback: "Use Command + number to open or switch to pinned Dock apps."),
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
                SettingsGroup {
                    HStack(spacing: 16) {
                        Text(AppLocalization.string("settings.dockIncludeFinder", fallback: "Count Finder as the first app (⌘1)"))
                        Spacer(minLength: 8)
                        Toggle(
                            AppLocalization.string("settings.dockIncludeFinder", fallback: "Count Finder as the first app (⌘1)"),
                            isOn: $includesFinder
                        )
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .accessibilityLabel(AppLocalization.string("settings.dockIncludeFinder", fallback: "Count Finder as the first app (⌘1)"))
                    }
                    .padding(.vertical, 10)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(AppLocalization.string("settings.currentShortcuts", fallback: "Current shortcuts"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SettingsGroup {
                        if controller.shortcuts.isEmpty {
                            Text(AppLocalization.string("settings.dockShortcutsEmpty", fallback: "Pin an app to the Dock to assign a shortcut."))
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 12)
                        } else {
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
                    }
                    Text(AppLocalization.string("settings.dockOrderHint", fallback: "Updates with Dock order · ⌘0 opens the tenth app"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.5)

            DisclosureGroup(AppLocalization.string("settings.dockHelp", fallback: "Shortcut rules")) {
                Text(AppLocalization.string("settings.dockShortcutsHint", fallback: "Number keys 1–9 and 0 follow pinned Dock apps. Recent apps, folders and spacers are skipped. Assigned shortcuts replace the current app’s Command + number actions until this feature is turned off."))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            }
            .font(.callout)
        }
    }
}
