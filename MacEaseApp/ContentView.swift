import AppKit
import SwiftUI

enum SettingsPage: String, CaseIterable, Identifiable {
    case finder, scroll, dock, keyboard, permissions, about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .finder: "Finder"
        case .scroll: AppLocalization.string("settings.scrollDirectionTitle", fallback: "Scroll direction")
        case .dock: AppLocalization.string("settings.dockShortcutsTitle", fallback: "Dock app shortcuts")
        case .keyboard: AppLocalization.string("settings.keyboardMappingTitle", fallback: "Keyboard mapping")
        case .permissions: AppLocalization.string("settings.permissionsTitle", fallback: "Permissions & Extensions")
        case .about: AppLocalization.string("settings.aboutTitle", fallback: "About MacEase")
        }
    }

    var symbol: String {
        switch self {
        case .finder: "folder.badge.plus"
        case .scroll: "computermouse"
        case .dock: "command"
        case .keyboard: "keyboard"
        case .permissions: "lock.shield"
        case .about: "info.circle"
        }
    }

    var sidebarTitle: String {
        self == .permissions
            ? AppLocalization.string("settings.permissionsNavigation", fallback: "Permissions")
            : title
    }
}

struct ContentView: View {
    @AppStorage("settingsSelectedPage") private var selectedPageName = SettingsPage.finder.rawValue
    @StateObject private var status = SettingsStatus()
    @ObservedObject private var dockController = DockShortcutController.shared
    @AppStorage(ScrollDirectionPreferences.isEnabledKey) private var scrollEnabled = false
    @AppStorage(ScrollDirectionPreferences.trackpadModeKey) private var trackpadMode = "natural"
    @AppStorage(ScrollDirectionPreferences.mouseModeKey) private var mouseMode = "reversed"
    @AppStorage(DockShortcutPreferences.isEnabledKey) private var dockEnabled = false
    @AppStorage(DockShortcutPreferences.includesFinderKey) private var includesFinder = false
    @AppStorage(KeyboardMappingPreferences.isEnabledKey) private var keyboardEnabled = false

    private var selectedPage: SettingsPage {
        SettingsPage(rawValue: selectedPageName) ?? .finder
    }

    private var selection: Binding<SettingsPage?> {
        Binding(
            get: { selectedPage },
            set: { if let page = $0 { selectedPageName = page.rawValue } }
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                List(selection: selection) {
                    Section(AppLocalization.string("settings.featuresGroup", fallback: "Features")) {
                        ForEach([SettingsPage.finder, .scroll, .dock, .keyboard]) { page in
                            sidebarRow(page)
                        }
                    }
                    Section(AppLocalization.string("settings.appGroup", fallback: "App")) {
                        ForEach([SettingsPage.permissions, .about]) { page in
                            sidebarRow(page)
                        }
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                .accessibilityIdentifier("settings.sidebar")

                VStack(alignment: .leading, spacing: 3) {
                    Text("MacEase").fontWeight(.medium)
                    Text(AppVersion.shortVersion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .frame(width: 190)
            .background(.regularMaterial)

            Divider()

            ScrollView {
                detail
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(28)
            }
            .id(selectedPage)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 700, minHeight: 480)
        .onAppear { status.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            status.refresh()
        }
        // Keep preference observers in the navigation container so changes
        // from the menu bar also apply while another settings page is visible.
        .onChange(of: scrollEnabled) { _ in status.reloadScrollDirection() }
        .onChange(of: trackpadMode) { _ in status.reloadScrollDirection() }
        .onChange(of: mouseMode) { _ in status.reloadScrollDirection() }
        .onChange(of: dockEnabled) { _ in dockController.reloadPreferences() }
        .onChange(of: includesFinder) { _ in dockController.reloadPreferences() }
        .onChange(of: keyboardEnabled) { _ in status.reloadKeyboardMapping() }
    }

    private func sidebarRow(_ page: SettingsPage) -> some View {
        HStack {
            Label(page.sidebarTitle, systemImage: page.symbol)
            Spacer(minLength: 0)
            if needsAttention(page) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                    .accessibilityLabel(AppLocalization.string("settings.needsAttention", fallback: "Needs attention"))
            }
        }
        .tag(page)
        .padding(.vertical, 3)
        .accessibilityIdentifier("settings.page.\(page.rawValue)")
    }

    private func needsAttention(_ page: SettingsPage) -> Bool {
        switch page {
        case .finder, .permissions:
            status.extensionIsEnabled == false || !status.accessibilityIsGranted
        case .scroll:
            scrollEnabled && !status.scrollDirectionIsRunning
        case .dock:
            dockEnabled && (dockController.failedToStart
                || !dockController.unavailablePositions.isEmpty
                || dockController.launchError != nil)
        case .keyboard:
            keyboardEnabled && !status.keyboardMappingIsRunning
        case .about:
            false
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch selectedPage {
        case .finder:
            FinderSettingsView(status: status, openPermissions: openPermissions)
        case .scroll:
            ScrollSettingsView(status: status, openPermissions: openPermissions)
        case .dock:
            DockSettingsView()
        case .keyboard:
            KeyboardSettingsView(status: status, openPermissions: openPermissions)
        case .permissions:
            PermissionsSettingsView(status: status)
        case .about:
            AboutSettingsView()
        }
    }

    private func openPermissions() {
        selectedPageName = SettingsPage.permissions.rawValue
    }
}
