import AppKit
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

        Settings {
            ContentView()
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

    func application(_ application: NSApplication, open urls: [URL]) {
        urls.forEach(creationRequestHandler.handle)
    }
}
