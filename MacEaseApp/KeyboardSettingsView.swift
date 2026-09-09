import MacEaseCore
import SwiftUI

struct KeyboardSettingsView: View {
    @ObservedObject var status: SettingsStatus
    let openPermissions: () -> Void
    @AppStorage(KeyboardMappingPreferences.isEnabledKey) private var isEnabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsPageHeader(
                title: SettingsPage.keyboard.title,
                subtitle: AppLocalization.string("settings.keyboardMappingDescription", fallback: "Use Command + I/J/K/L as the up, left, down and right arrow keys."),
                isEnabled: $isEnabled,
                toggleLabel: AppLocalization.string("settings.enableKeyboardMapping", fallback: "Enable keyboard mapping")
            )

            if isEnabled && !status.keyboardMappingIsRunning {
                SettingsNotice(
                    message: AppLocalization.string(
                        status.accessibilityIsGranted ? "settings.keyboardUnavailable" : "settings.keyboardNeedsPermission",
                        fallback: status.accessibilityIsGranted ? "Keyboard mapping could not start." : "Accessibility access is needed to map keyboard shortcuts."
                    ),
                    actionTitle: AppLocalization.string("settings.goToPermissions", fallback: "Open Permissions & Extensions"),
                    action: openPermissions
                )
            }

            SettingsGroup {
                ForEach(KeyboardMapping.allCases) { mapping in
                    if mapping != .up { Divider() }
                    HStack(spacing: 16) {
                        Text(mapping.sourceLabel)
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                        Spacer(minLength: 8)
                        Text(mapping.arrow)
                            .font(.system(.title3, design: .monospaced))
                            .accessibilityHidden(true)
                        Text(AppLocalization.string("settings.keyboard.\(mapping.rawValue)", fallback: mapping.rawValue.capitalized))
                    }
                    .padding(.vertical, 10)
                }
            }
            .opacity(isEnabled ? 1 : 0.5)

            DisclosureGroup(AppLocalization.string("settings.keyboardHelp", fallback: "Mapping rules")) {
                Text(AppLocalization.string("settings.keyboardMappingHint", fallback: "Uses the physical I/J/K/L keys with Command only. Hold to repeat. Shortcuts with Shift, Option, Control or Fn keep their original behavior. While enabled, these four shortcuts replace the current app’s actions; turn this feature off to restore them."))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            }
            .font(.callout)
        }
    }
}
