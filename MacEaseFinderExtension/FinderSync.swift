import AppKit
import FinderSync
#if canImport(MacEaseCore)
import MacEaseCore
#endif

final class FinderSync: FIFinderSync {
    private let directoryResolver = TargetDirectoryResolver()
    private var activeMenuLocation = FinderMenuLocation.container

    override init() {
        super.init()

        // Monitoring the file-system root makes the commands available in all
        // local Finder folders, including mounted volumes below /Volumes.
        FIFinderSyncController.default().directoryURLs = [
            URL(fileURLWithPath: "/", isDirectory: true)
        ]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        activeMenuLocation = location(for: menuKind)

        let menu = NSMenu(title: "MacEase")
        menu.addItem(menuItem(
            title: Self.localized(
                "finder.newFile",
                fallback: "New File"
            ),
            systemImage: "doc.badge.plus",
            action: #selector(createFile)
        ))
        menu.addItem(menuItem(
            title: Self.localized(
                "finder.newFolder",
                fallback: "New Folder"
            ),
            systemImage: "folder.badge.plus",
            action: #selector(createFolder)
        ))
        return menu
    }

    @objc private func createFile() {
        performCreation(of: .file)
    }

    @objc private func createFolder() {
        performCreation(of: .folder)
    }

    private func performCreation(of kind: CreationKind) {
        let controller = FIFinderSyncController.default()
        guard let directory = directoryResolver.resolve(
            menuLocation: activeMenuLocation,
            targetedURL: controller.targetedURL(),
            selectedItemURLs: controller.selectedItemURLs() ?? []
        ) else {
            presentError(Self.localized(
                "finder.error.location",
                fallback: "The destination could not be determined."
            ))
            return
        }

        guard let requestURL = CreationRequest(kind: kind, directoryURL: directory).url else {
            presentError(Self.localized(
                "finder.error.request",
                fallback: "The creation request could not be generated."
            ))
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        configuration.addsToRecentItems = false
        configuration.promptsUserIfNeeded = false
        let errorTitle = Self.localized(
            "finder.error.title",
            fallback: "Unable to Create"
        )
        let openAppError = Self.localized(
            "finder.error.openApp",
            fallback: "MacEase could not be opened. Run the main app once and try again."
        )
        let okTitle = Self.localized("common.ok", fallback: "OK")
        NSWorkspace.shared.open(requestURL, configuration: configuration) { _, error in
            guard error != nil else { return }
            Task { @MainActor in
                let alert = NSAlert()
                alert.alertStyle = .warning
                alert.messageText = errorTitle
                alert.informativeText = openAppError
                alert.addButton(withTitle: okTitle)
                alert.runModal()
            }
        }
    }

    private func presentError(_ message: String) {
        let errorTitle = Self.localized(
            "finder.error.title",
            fallback: "Unable to Create"
        )
        let okTitle = Self.localized("common.ok", fallback: "OK")
        Task { @MainActor in
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = errorTitle
            alert.informativeText = message
            alert.addButton(withTitle: okTitle)
            NSApplication.shared.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }

    private func menuItem(title: String, systemImage: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.image = NSImage(systemSymbolName: systemImage, accessibilityDescription: title)
        return item
    }

    private static func localized(_ key: String, fallback: String) -> String {
        NSLocalizedString(
            key,
            tableName: nil,
            bundle: Bundle(for: FinderSync.self),
            value: fallback,
            comment: ""
        )
    }

    private func location(for menuKind: FIMenuKind) -> FinderMenuLocation {
        switch menuKind {
        case .contextualMenuForContainer:
            .container
        case .contextualMenuForItems:
            .items
        case .contextualMenuForSidebar:
            .sidebar
        case .toolbarItemMenu:
            .toolbar
        @unknown default:
            .container
        }
    }
}
