import FinderSync
import SwiftUI

struct PermissionsSettingsView: View {
    @ObservedObject var status: SettingsStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsPageHeader(
                title: SettingsPage.permissions.title,
                subtitle: AppLocalization.string("settings.permissionsDescription", fallback: "Manage the system access used by MacEase features.")
            )

            SettingsGroup {
                permissionRow(
                    title: AppLocalization.string("settings.finderExtension", fallback: "Finder extension"),
                    purpose: AppLocalization.string("settings.finderExtensionPurpose", fallback: "For Finder context-menu actions"),
                    isGranted: status.extensionIsEnabled,
                    action: FIFinderSyncController.showExtensionManagementInterface
                )
                Divider()
                permissionRow(
                    title: AppLocalization.string("settings.accessibility", fallback: "Accessibility"),
                    purpose: AppLocalization.string("settings.accessibilityPurpose", fallback: "For in-place renaming, scroll direction control and keyboard mapping"),
                    isGranted: status.accessibilityIsGranted,
                    action: status.openAccessibilitySettings
                )
            }

            Text(AppLocalization.string("settings.dockNoPermission", fallback: "Dock app shortcuts do not need Accessibility access."))
                .font(.caption)
                .foregroundStyle(.secondary)

            DisclosureGroup(AppLocalization.string("settings.permissionTroubleshooting", fallback: "Permission troubleshooting")) {
                Text(AppLocalization.string("settings.scrollPermissionHint", fallback: "If a feature still cannot start after granting access, remove the old MacEase entry in System Settings, add /Applications/MacEase.app again, and reopen the app."))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            }
            .font(.callout)
        }
    }

    private func permissionRow(
        title: String,
        purpose: String,
        isGranted: Bool?,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                Text(purpose)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Text(isGranted.map { granted in
                granted
                    ? AppLocalization.string("settings.permissionGranted", fallback: "Enabled")
                    : AppLocalization.string("settings.permissionNeeded", fallback: "Not enabled")
            } ?? AppLocalization.string("settings.permissionChecking", fallback: "Checking…"))
                .font(.caption)
                .foregroundStyle(isGranted == false ? Color.orange : Color.secondary)
                .fixedSize()
            Button(
                isGranted == false
                    ? AppLocalization.string("settings.permissionEnable", fallback: "Enable…")
                    : AppLocalization.string("settings.permissionManage", fallback: "Manage…"),
                action: action
            )
            .fixedSize()
            .accessibilityLabel(title + ", " + AppLocalization.string("settings.permissionManage", fallback: "Manage…"))
        }
        .padding(.vertical, 12)
    }
}
