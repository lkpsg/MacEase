import AppKit
import FinderSync
import SwiftUI

@MainActor
final class SettingsStatus: ObservableObject {
    @Published private(set) var extensionIsEnabled: Bool?
    @Published private(set) var accessibilityIsGranted = FinderRenameController().isAccessibilityGranted
    @Published private(set) var scrollDirectionIsRunning = false

    func refresh() {
        accessibilityIsGranted = FinderRenameController().isAccessibilityGranted
        reloadScrollDirection()
        DockShortcutController.shared.reloadPreferences()
        Task {
            extensionIsEnabled = await Task.detached {
                FIFinderSyncController.isExtensionEnabled
            }.value
        }
    }

    func reloadScrollDirection() {
        scrollDirectionIsRunning = ScrollDirectionController.shared.reloadPreferences()
    }

    func openAccessibilitySettings() {
        let controller = FinderRenameController()
        if !controller.isAccessibilityGranted {
            controller.requestAccessibilityPermission()
        }
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

enum AppVersion {
    static var shortVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    static var description: String {
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return String(format: AppLocalization.string("settings.version", fallback: "Version %@ (%@)"), shortVersion, build)
    }
}

struct SettingsPageHeader: View {
    let title: String
    let subtitle: String
    var isEnabled: Binding<Bool>?
    var toggleLabel = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold))
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                if let isEnabled {
                    Toggle(toggleLabel, isOn: isEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .accessibilityLabel(toggleLabel)
                }
            }
            Text(subtitle)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 4)
    }
}

struct SettingsGroup<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
        }
    }
}

struct SettingsNotice: View {
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 6) {
                Text(message)
                    .fixedSize(horizontal: false, vertical: true)
                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .buttonStyle(.link)
                }
            }
            Spacer(minLength: 0)
        }
        .font(.callout)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}
