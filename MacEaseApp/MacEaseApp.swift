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
        // Finder creation requests launch the app with their URL attached and
        // must stay in the background. A normal Dock/Finder launch has no URL,
        // so show the settings window immediately.
        let isHandlingCreationRequest = ProcessInfo.processInfo.arguments.contains { argument in
            argument.hasPrefix("\(CreationRequest.urlScheme)://")
        }
        if !isHandlingCreationRequest {
            DispatchQueue.main.async {
                SettingsWindowPresenter.open()
            }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
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
}

@MainActor
enum SettingsWindowPresenter {
    private static var windowController: NSWindowController?

    static func open() {
        let application = NSApplication.shared
        application.activate(ignoringOtherApps: true)

        if windowController == nil {
            let contentSize = NSSize(width: 500, height: 520)
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
            windowController = NSWindowController(window: window)
        }

        guard let window = windowController?.window else { return }
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        windowController?.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }
}
