import FinderSync
import SwiftUI

struct ContentView: View {
    @State private var extensionIsEnabled = FIFinderSyncController.isExtensionEnabled
    @State private var accessibilityIsGranted = FinderRenameController().isAccessibilityGranted

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
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
                            "settings.renameEnabled",
                            fallback: "In-place Finder renaming is enabled"
                        )
                        : AppLocalization.string(
                            "settings.renamePermissionRequired",
                            fallback: "Accessibility access is required to start renaming automatically"
                        ),
                    systemImage: accessibilityIsGranted ? "checkmark.circle.fill" : "exclamationmark.circle"
                )
                .foregroundStyle(accessibilityIsGranted ? .green : .secondary)

                Spacer()

                if !accessibilityIsGranted {
                    Button(AppLocalization.string(
                        "settings.allow",
                        fallback: "Allow…"
                    )) {
                        accessibilityIsGranted = FinderRenameController()
                            .requestAccessibilityPermission()
                    }
                }
            }

            Text(AppLocalization.string(
                "settings.firstUseHint",
                fallback: "On first use, enable “MacEase Finder Extension” in the System Settings window that opens."
            ))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(32)
        .frame(width: 500)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            extensionIsEnabled = FIFinderSyncController.isExtensionEnabled
            accessibilityIsGranted = FinderRenameController().isAccessibilityGranted
        }
    }
}
