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
            title: "新建文件",
            systemImage: "doc.badge.plus",
            action: #selector(createFile)
        ))
        menu.addItem(menuItem(
            title: "新建文件夹",
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
            presentError("无法确定创建位置。")
            return
        }

        guard let requestURL = CreationRequest(kind: kind, directoryURL: directory).url else {
            presentError("无法生成创建请求。")
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        configuration.addsToRecentItems = false
        configuration.promptsUserIfNeeded = false
        NSWorkspace.shared.open(requestURL, configuration: configuration) { _, error in
            guard error != nil else { return }
            Task { @MainActor in
                let alert = NSAlert()
                alert.alertStyle = .warning
                alert.messageText = "无法创建"
                alert.informativeText = "无法打开 MacEase，请先运行一次主应用。"
                alert.addButton(withTitle: "好")
                alert.runModal()
            }
        }
    }

    private func presentError(_ message: String) {
        Task { @MainActor in
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "无法创建"
            alert.informativeText = message
            alert.addButton(withTitle: "好")
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
