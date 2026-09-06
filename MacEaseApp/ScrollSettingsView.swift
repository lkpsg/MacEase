import MacEaseCore
import SwiftUI

struct ScrollSettingsView: View {
    @ObservedObject var status: SettingsStatus
    let openPermissions: () -> Void
    @AppStorage(ScrollDirectionPreferences.isEnabledKey) private var isEnabled = false
    @AppStorage(ScrollDirectionPreferences.trackpadModeKey) private var trackpadMode = ScrollDirectionMode.natural.rawValue
    @AppStorage(ScrollDirectionPreferences.mouseModeKey) private var mouseMode = ScrollDirectionMode.reversed.rawValue

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsPageHeader(
                title: SettingsPage.scroll.title,
                subtitle: AppLocalization.string("settings.scrollDirectionDescription", fallback: "Choose a scroll direction for each input device."),
                isEnabled: $isEnabled,
                toggleLabel: AppLocalization.string("settings.enableScrollDirection", fallback: "Control scroll direction")
            )

            if isEnabled && !status.scrollDirectionIsRunning {
                SettingsNotice(
                    message: AppLocalization.string(
                        status.accessibilityIsGranted ? "settings.scrollUnavailable" : "settings.scrollNeedsPermission",
                        fallback: status.accessibilityIsGranted ? "Scroll direction control could not start." : "Accessibility access is needed to control scrolling."
                    ),
                    actionTitle: AppLocalization.string("settings.goToPermissions", fallback: "Open Permissions & Extensions"),
                    action: openPermissions
                )
            }

            SettingsGroup {
                directionPicker(title: AppLocalization.string("settings.trackpad", fallback: "Trackpad"), selection: $trackpadMode)
                Divider()
                directionPicker(title: AppLocalization.string("settings.mouseWheel", fallback: "Mouse wheel"), selection: $mouseMode)
            }
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.5)

            DisclosureGroup(AppLocalization.string("settings.scrollHelp", fallback: "About scroll directions")) {
                Text(AppLocalization.string("settings.scrollModeHint", fallback: "Natural moves content with the gesture; Reversed moves it in the opposite direction."))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            }
            .font(.callout)
        }
    }

    private func directionPicker(title: String, selection: Binding<String>) -> some View {
        HStack(spacing: 16) {
            Text(title)
            Spacer(minLength: 8)
            Picker(title, selection: selection) {
                Text(AppLocalization.string("settings.scrollNatural", fallback: "Natural"))
                    .tag(ScrollDirectionMode.natural.rawValue)
                Text(AppLocalization.string("settings.scrollReversed", fallback: "Reversed"))
                    .tag(ScrollDirectionMode.reversed.rawValue)
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .fixedSize()
        }
        .padding(.vertical, 10)
    }
}
