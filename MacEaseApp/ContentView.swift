import AppKit
import FinderSync
import MacEaseCore
import SwiftUI

struct ContentView: View {
    @State private var extensionIsEnabled = false
    @State private var accessibilityIsGranted = FinderRenameController().isAccessibilityGranted
    @State private var scrollDirectionIsRunning = false
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
