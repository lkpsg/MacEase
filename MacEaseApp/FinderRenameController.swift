import AppKit
import ApplicationServices

@MainActor
final class FinderRenameController {
    var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    func requestAccessibilityPermission() -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": true]
            as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func selectAndBeginRenaming(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
        guard isAccessibilityGranted else { return }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            sendRenameKeystrokeToFinder()
        }
    }

    private func sendRenameKeystrokeToFinder() {
        guard let finder = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.finder"
        ).first else {
            return
        }

        let source = CGEventSource(stateID: .hidSystemState)
        let returnKeyCode: CGKeyCode = 36
        CGEvent(keyboardEventSource: source, virtualKey: returnKeyCode, keyDown: true)?
            .postToPid(finder.processIdentifier)
        CGEvent(keyboardEventSource: source, virtualKey: returnKeyCode, keyDown: false)?
            .postToPid(finder.processIdentifier)
    }
}
