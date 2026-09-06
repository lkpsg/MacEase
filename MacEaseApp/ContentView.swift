import AppKit
import FinderSync
import MacEaseCore
import SwiftUI

struct ContentView: View {
    @State private var extensionIsEnabled = false
    @State private var accessibilityIsGranted = FinderRenameController().isAccessibilityGranted
    @State private var scrollDirectionIsRunning = false
    @ObservedObject private var dockShortcutController = DockShortcutController.shared
    @AppStorage(DockShortcutPreferences.isEnabledKey)
    private var dockShortcutsIsEnabled = false
    @AppStorage(DockShortcutPreferences.includesFinderKey)
    private var dockShortcutsIncludeFinder = false
    @AppStorage(ScrollDirectionPreferences.isEnabledKey)
    private var scrollDirectionIsEnabled = false
    @AppStorage(ScrollDirectionPreferences.trackpadModeKey)
    private var trackpadMode = ScrollDirectionMode.natural.rawValue
    @AppStorage(ScrollDirectionPreferences.mouseModeKey)
    private var mouseMode = ScrollDirectionMode.reversed.rawValue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 16) {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable()
                        .frame(width: 72, height: 72)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("MacEase")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text(AppLocalization.string(
                            "settings.tagline",
                            fallback: "Make everyday macOS tasks easier"
                        ))
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                finderCreationSection

                Divider()

                scrollDirectionSection

                Divider()

                dockShortcutsSection
            }
            .padding(32)
        }
        .frame(width: 560, height: 700)
        .onAppear {
            refreshStatuses()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshStatuses()
        }
        .onChange(of: scrollDirectionIsEnabled) { _ in
            applyScrollDirectionPreferences()
        }
        .onChange(of: trackpadMode) { _ in
            reloadScrollDirectionController()
        }
        .onChange(of: mouseMode) { _ in
            reloadScrollDirectionController()
        }
        .onChange(of: dockShortcutsIsEnabled) { _ in
            dockShortcutController.reloadPreferences()
        }
        .onChange(of: dockShortcutsIncludeFinder) { _ in
            dockShortcutController.reloadPreferences()
        }
    }

    private var finderCreationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(
                AppLocalization.string(
                    "settings.finderCreationTitle",
                    fallback: "Create from the Finder context menu"
                ),
                systemImage: "folder.badge.plus"
            )
                .font(.headline)

            Text(AppLocalization.string(
                "settings.finderCreationDescription",
                fallback: "Create an item immediately and rename it in place in Finder, without opening a MacEase window."
            ))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Circle()
                    .fill(extensionIsEnabled ? Color.green : Color.orange)
                    .frame(width: 9, height: 9)
                Text(extensionIsEnabled
                    ? AppLocalization.string(
                        "settings.finderExtensionEnabled",
                        fallback: "Finder extension is enabled"
                    )
                    : AppLocalization.string(
                        "settings.finderExtensionRequired",
                        fallback: "Finder extension needs to be enabled"
                    ))
                    .fontWeight(.medium)
            }

            Button(extensionIsEnabled
                ? AppLocalization.string(
                    "settings.manageFinderExtension",
                    fallback: "Manage Finder Extension…"
                )
                : AppLocalization.string(
                    "settings.enableFinderExtension",
                    fallback: "Enable Finder Extension…"
                )) {
                FIFinderSyncController.showExtensionManagementInterface()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            HStack(spacing: 12) {
                Label(
                    accessibilityIsGranted
                        ? AppLocalization.string(
                            "settings.accessibilityEnabled",
                            fallback: "Accessibility access is enabled"
                        )
                        : AppLocalization.string(
                            "settings.accessibilityPermissionRequired",
                            fallback: "Accessibility access is required for in-place renaming and scroll direction control"
                        ),
                    systemImage: accessibilityIsGranted ? "checkmark.circle.fill" : "exclamationmark.circle"
                )
                .foregroundStyle(accessibilityIsGranted ? .green : .secondary)

                Spacer()

                if !accessibilityIsGranted {
                    Button(AppLocalization.string(
                        "settings.openAccessibilitySettings",
                        fallback: "Open System Settings…"
                    )) {
                        accessibilityIsGranted = FinderRenameController()
                            .requestAccessibilityPermission()
                    }
                }
            }

            Text(AppLocalization.string(
                "settings.firstUseHint",
                fallback: "On first use, enable the Finder extension and allow Accessibility access in System Settings."
            ))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var scrollDirectionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(
                AppLocalization.string(
                    "settings.scrollDirectionTitle",
                    fallback: "Scroll direction"
                ),
                systemImage: "arrow.up.and.down"
            )
                .font(.headline)

            Text(AppLocalization.string(
                "settings.scrollDirectionDescription",
                fallback: "Choose natural or reversed scrolling independently for the trackpad and mouse wheel."
            ))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(
                AppLocalization.string(
                    "settings.enableScrollDirection",
                    fallback: "Control scroll direction"
                ),
                isOn: $scrollDirectionIsEnabled
            )
            .toggleStyle(.switch)

            if scrollDirectionIsEnabled {
                directionPicker(
                    titleKey: "settings.trackpad",
                    fallback: "Trackpad",
                    selection: $trackpadMode
                )
                directionPicker(
                    titleKey: "settings.mouseWheel",
                    fallback: "Mouse wheel",
                    selection: $mouseMode
                )

                Text(AppLocalization.string(
                    "settings.scrollModeHint",
                    fallback: "Natural moves content with the gesture; Reversed moves it in the opposite direction."
                ))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if accessibilityIsGranted && scrollDirectionIsRunning {
                    Label(
                        AppLocalization.string(
                            "settings.scrollActive",
                            fallback: "Scroll direction control is active"
                        ),
                        systemImage: "checkmark.circle.fill"
                    )
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text(AppLocalization.string(
                        "settings.scrollPermissionHint",
                        fallback: "macOS has not granted access to this MacEase process. If MacEase is already enabled in System Settings, remove the old entry, add /Applications/MacEase.app again, and reopen the app."
                    ))
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var dockShortcutsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(
                AppLocalization.string("settings.dockShortcutsTitle", fallback: "Dock app shortcuts"),
                systemImage: "command"
            )
            .font(.headline)

            Text(AppLocalization.string(
                "settings.dockShortcutsDescription",
                fallback: "Use Command + 1–9 and 0 to open or switch to the first ten pinned apps in Dock order. 0 opens the tenth app."
            ))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            Toggle(
                AppLocalization.string("settings.enableDockShortcuts", fallback: "Enable Dock app shortcuts"),
                isOn: $dockShortcutsIsEnabled
            )
            .toggleStyle(.switch)

            if dockShortcutsIsEnabled {
                Toggle(
                    AppLocalization.string("settings.dockIncludeFinder", fallback: "Count Finder as the first app (⌘1)"),
                    isOn: $dockShortcutsIncludeFinder
                )

                Text(AppLocalization.string(
                    "settings.dockShortcutsHint",
                    fallback: "Shortcuts follow Dock changes automatically. Recent apps, folders and spacers are skipped. These shortcuts take priority over the current app’s Command + number actions. No Accessibility access is needed."
                ))
                .font(.caption)
                .foregroundStyle(.secondary)

                ForEach(dockShortcutController.shortcuts) { shortcut in
                    HStack(spacing: 10) {
                        Text(shortcut.label)
                            .font(.system(.body, design: .monospaced).weight(.medium))
                            .frame(width: 36, alignment: .leading)
                        Image(nsImage: NSWorkspace.shared.icon(forFile: shortcut.application.url.path))
                            .resizable()
                            .frame(width: 22, height: 22)
                        Text(shortcut.application.name)
                            .lineLimit(1)
                        Spacer()
                        if dockShortcutController.unavailablePositions.contains(shortcut.position) {
                            Text(AppLocalization.string("settings.dockShortcutUnavailable", fallback: "Unavailable"))
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                if dockShortcutController.failedToStart || !dockShortcutController.unavailablePositions.isEmpty {
                    Text(AppLocalization.string(
                        "settings.dockShortcutsConflict",
                        fallback: "Some shortcuts could not be registered. Quit Snap or another app using the same shortcuts; MacEase retries automatically."
                    ))
                    .font(.caption)
                    .foregroundStyle(.orange)
                } else if dockShortcutController.shortcuts.isEmpty {
                    Text(AppLocalization.string("settings.dockShortcutsEmpty", fallback: "Pin an app to the Dock to assign a shortcut."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Label(
                        AppLocalization.string("settings.dockShortcutsActive", fallback: "Dock app shortcuts are active"),
                        systemImage: "checkmark.circle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.green)
                }

                if let error = dockShortcutController.launchError {
                    Text(AppLocalization.string("settings.dockLaunchError", fallback: "Unable to open app: ") + error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private func directionPicker(
        titleKey: String,
        fallback: String,
        selection: Binding<String>
    ) -> some View {
        HStack(spacing: 16) {
            Text(AppLocalization.string(titleKey, fallback: fallback))
                .frame(width: 110, alignment: .leading)

            Picker("", selection: selection) {
                Text(AppLocalization.string(
                    "settings.scrollNatural",
                    fallback: "Natural"
                ))
                    .tag(ScrollDirectionMode.natural.rawValue)
                Text(AppLocalization.string(
                    "settings.scrollReversed",
                    fallback: "Reversed"
                ))
                    .tag(ScrollDirectionMode.reversed.rawValue)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private func refreshStatuses() {
        refreshFinderExtensionStatus()
        accessibilityIsGranted = FinderRenameController().isAccessibilityGranted
        reloadScrollDirectionController()
        dockShortcutController.reloadPreferences()
    }

    private func applyScrollDirectionPreferences() {
        reloadScrollDirectionController()
    }

    private func reloadScrollDirectionController() {
        scrollDirectionIsRunning = ScrollDirectionController.shared.reloadPreferences()
    }

    private func refreshFinderExtensionStatus() {
        DispatchQueue.global(qos: .userInitiated).async {
            let isEnabled = FIFinderSyncController.isExtensionEnabled
            DispatchQueue.main.async {
                extensionIsEnabled = isEnabled
            }
        }
    }
}
