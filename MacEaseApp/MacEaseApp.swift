import AppKit
import MacEaseCore
import SwiftUI

@main
struct MacEaseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
        } label: {
            MenuBarIconView()
        }
    }
}

private struct MenuBarIconView: View {
    var body: some View {
        if let image = menuBarImage {
            Image(nsImage: image)
        } else {
            Image(systemName: "sparkles")
        }
    }

    private var menuBarImage: NSImage? {
        guard let url = Bundle.main.url(
            forResource: "MenuBarIconTemplate",
            withExtension: "png"
        ), let image = NSImage(contentsOf: url) else {
            return nil
        }

        image.isTemplate = true
        image.size = NSSize(width: 18, height: 18)
        return image
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let creationRequestHandler = CreationRequestHandler()

    func applicationDidFinishLaunching(_ notification: Notification) {
        ScrollDirectionController.shared.reloadPreferences()

        // Finder creation requests launch the app with their URL attached and
        // must stay in the background. A normal Dock/Finder launch has no URL,
        // so show the settings window immediately.
        let isHandlingCreationRequest = ProcessInfo.processInfo.arguments.contains { argument in
            argument.hasPrefix("\(CreationRequest.urlScheme)://")
        }
        if isHandlingCreationRequest {
            NSApplication.shared.setActivationPolicy(.accessory)
        } else {
            DispatchQueue.main.async {
                SettingsWindowPresenter.open()
            }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        if !SettingsWindowPresenter.isVisible {
            application.setActivationPolicy(.accessory)
        }
        urls.forEach(creationRequestHandler.handle)
    }

    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        SettingsWindowPresenter.open()
        return true
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        if !flag {
            SettingsWindowPresenter.open()
        }
        return true
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        ScrollDirectionController.shared.reloadPreferences()
    }
}

@MainActor
enum SettingsWindowPresenter {
    private static var windowController: SettingsWindowController?

    static var isVisible: Bool {
        windowController?.window?.isVisible == true
    }

    static func open() {
        let application = NSApplication.shared
        application.setActivationPolicy(.regular)
        application.activate(ignoringOtherApps: true)

        if windowController == nil {
            let contentSize = NSSize(width: 560, height: 700)
            let hostingView = NSHostingView(rootView: ContentView())
            hostingView.frame = NSRect(origin: .zero, size: contentSize)
            hostingView.autoresizingMask = [.width, .height]

            let window = NSWindow(
                contentRect: NSRect(origin: .zero, size: contentSize),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "MacEase"
            window.contentView = hostingView
            window.contentMinSize = contentSize
            window.contentMaxSize = contentSize
            window.isReleasedWhenClosed = false
            window.setFrameAutosaveName("MacEaseSettingsWindow")
            window.center()
            windowController = SettingsWindowController(window: window)
        }

        guard let window = windowController?.window else { return }
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        windowController?.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }
}

@MainActor
private final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    override init(window: NSWindow?) {
        super.init(window: window)
        window?.delegate = self
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}
