import SwiftUI

struct FinderSettingsView: View {
    @ObservedObject var status: SettingsStatus
    let openPermissions: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsPageHeader(
                title: "Finder",
                subtitle: AppLocalization.string("settings.finderCreationDescription", fallback: "Create files and folders directly from the context menu.")
            )

            if status.extensionIsEnabled == false {
                SettingsNotice(
                    message: AppLocalization.string("settings.finderExtensionRequired", fallback: "Enable the Finder extension to use context-menu actions."),
                    actionTitle: AppLocalization.string("settings.goToPermissions", fallback: "Open Permissions & Extensions"),
                    action: openPermissions
                )
            } else if !status.accessibilityIsGranted {
                SettingsNotice(
                    message: AppLocalization.string("settings.renamePermissionHint", fallback: "In-place renaming needs Accessibility access. You can still create files and folders."),
                    actionTitle: AppLocalization.string("settings.goToPermissions", fallback: "Open Permissions & Extensions"),
                    action: openPermissions
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(AppLocalization.string("settings.contextMenu", fallback: "Context menu"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SettingsGroup {
                    Label(AppLocalization.string("settings.newFile", fallback: "New File"), systemImage: "doc.badge.plus")
                        .padding(.vertical, 12)
                    Divider()
                    Label(AppLocalization.string("settings.newFolder", fallback: "New Folder"), systemImage: "folder.badge.plus")
                        .padding(.vertical, 12)
                }
                Text(AppLocalization.string("settings.finderRenameHint", fallback: "Name new items in Finder immediately after creation."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            DisclosureGroup(AppLocalization.string("settings.finderHelp", fallback: "Setup and usage help")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(AppLocalization.string("settings.firstUseHint", fallback: "Enable the Finder extension for context-menu actions and allow Accessibility access for in-place renaming."))
                    Button(AppLocalization.string("settings.goToPermissions", fallback: "Open Permissions & Extensions"), action: openPermissions)
                        .buttonStyle(.link)
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            }
            .font(.callout)
        }
    }
}
