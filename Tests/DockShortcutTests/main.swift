import AppKit
import Carbon
import MacEaseCore

private struct TestFailure: Error {
    let message: String
}

@main
@MainActor
enum DockShortcutTests {
    static func main() {
        NSApplication.shared.setActivationPolicy(.accessory)
        Task { @MainActor in
            do {
                try await run()
                print("✅ Dock shortcut integration tests passed")
                exit(0)
            } catch {
                print("✗ \(error)")
                exit(1)
            }
        }
        NSApplication.shared.run()
    }

    private static func run() async throws {
        let suite = "com.lkpsg.MacEase.DockShortcutTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var apps = (1...12).map {
            DockApplication(url: URL(fileURLWithPath: "/Applications/Fixture\($0).app"), name: "Fixture\($0)")
        }
        var launched: [URL] = []
        let controller = DockShortcutController(
            defaults: defaults,
            readApplications: { includeFinder in
                (includeFinder ? [DockApplication(url: DockApplicationParser.finderURL, name: "Finder")] : []) + apps
            },
            launchApplication: { launched.append($0) }
        )
        defer { controller.stop() }

        defaults.set(true, forKey: DockShortcutPreferences.isEnabledKey)
        controller.reloadPreferences()
        try expect(!controller.failedToStart && controller.unavailablePositions.isEmpty,
                   "Could not register hotkeys; quit Snap/MacEase and other Command + number shortcut utilities before this test.")
        try expect(controller.shortcuts.count == 10, "Expected ten registered shortcuts")
        print("✓ Registers Command + 1–9 and 0 with macOS")

        try sendHotKey(1, pressed: true)
        try sendHotKey(1, pressed: true)
        try expect(launched == [apps[0].url], "Holding a key must launch only once")
        try sendHotKey(1, pressed: false)
        try sendHotKey(1, pressed: true)
        try sendHotKey(1, pressed: false)
        try expect(launched.count == 2, "Releasing and pressing must launch again")
        print("✓ Routes hotkey events and suppresses repeats until release")

        apps.swapAt(0, 1)
        try sendHotKey(1, pressed: true)
        try sendHotKey(1, pressed: false)
        try expect(launched.last == apps[0].url, "Must read the Dock again before launching")
        print("✓ Uses a Dock reorder immediately, before the refresh timer")

        try sendHotKey(10, pressed: true)
        try sendHotKey(10, pressed: false)
        try expect(launched.last == apps[9].url, "Command + 0 must open the tenth app")

        if CommandLine.arguments.contains("--post-key-events") {
            guard CGPreflightPostEventAccess() else {
                throw TestFailure(message: "Keyboard event posting permission is required for --post-key-events")
            }
            let before = launched.count
            postKey(18, flags: .maskCommand)
            try await Task.sleep(for: .milliseconds(250))
            try expect(launched.count == before + 1 && launched.last == apps[0].url,
                       "Posted Command + 1 did not reach the registered global handler")
            postKey(29, flags: .maskCommand)
            try await Task.sleep(for: .milliseconds(250))
            try expect(launched.count == before + 2 && launched.last == apps[9].url,
                       "Posted Command + 0 did not reach the registered global handler")
            print("✓ Actual posted keyboard events reach Command + 1 and Command + 0 handlers")
        }

        defaults.set(true, forKey: DockShortcutPreferences.includesFinderKey)
        controller.reloadPreferences()
        try sendHotKey(1, pressed: true)
        try sendHotKey(1, pressed: false)
        try expect(launched.last == DockApplicationParser.finderURL, "Finder preference must shift positions")
        defaults.set(false, forKey: DockShortcutPreferences.includesFinderKey)

        apps = Array(apps.prefix(1))
        controller.reloadPreferences()
        var unusedReference: EventHotKeyRef?
        try expect(registerKey(19, reference: &unusedReference) == noErr, "Removing an app must release Command + 2")
        if let unusedReference { UnregisterEventHotKey(unusedReference) }
        print("✓ Finder preference and removed-slot hotkey cleanup")

        defaults.set(false, forKey: DockShortcutPreferences.isEnabledKey)
        controller.reloadPreferences()
        var conflictingReference: EventHotKeyRef?
        try expect(registerKey(18, reference: &conflictingReference) == noErr, "Disabling must release Command + 1")
        defer { if let conflictingReference { UnregisterEventHotKey(conflictingReference) } }

        defaults.set(true, forKey: DockShortcutPreferences.isEnabledKey)
        controller.reloadPreferences()
        try expect(controller.unavailablePositions == [1], "Conflicting registrations must be reported")
        let beforeConflict = launched.count
        try sendHotKey(1, pressed: true)
        try expect(launched.count == beforeConflict, "An unavailable shortcut must not launch an app")
        if let conflictingReference { UnregisterEventHotKey(conflictingReference) }
        conflictingReference = nil
        try await Task.sleep(for: .milliseconds(1200))
        try expect(controller.unavailablePositions.isEmpty, "Timer must retry when conflict is released")
        try sendHotKey(1, pressed: true)
        try sendHotKey(1, pressed: false)
        try expect(launched.count == beforeConflict + 1, "Recovered hotkey must launch")
        print("✓ Disabling releases keys; conflicts are reported and automatically retried")

        apps = []
        controller.reloadPreferences()
        try expect(controller.shortcuts.isEmpty, "Empty Dock must have no shortcuts")
        var emptyReference: EventHotKeyRef?
        try expect(registerKey(18, reference: &emptyReference) == noErr, "Empty Dock must release its last key")
        if let emptyReference { UnregisterEventHotKey(emptyReference) }
        print("✓ Empty Dock releases all hotkeys")
    }

    private static func sendHotKey(_ position: UInt32, pressed: Bool) throws {
        var event: EventRef?
        let status = CreateEvent(nil, OSType(kEventClassKeyboard),
                                 UInt32(pressed ? kEventHotKeyPressed : kEventHotKeyReleased),
                                 GetCurrentEventTime(), EventAttributes(kEventAttributeUserEvent), &event)
        guard status == noErr, let event else { throw TestFailure(message: "Could not create hotkey event") }
        defer { ReleaseEvent(event) }
        var identifier = EventHotKeyID(signature: 0x4D45444B, id: position)
        SetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                          MemoryLayout<EventHotKeyID>.size, &identifier)
        try expect(SendEventToEventTarget(event, GetApplicationEventTarget()) == noErr,
                   "Registered event handler did not handle the hotkey")
    }

    private static func registerKey(_ code: UInt32, reference: inout EventHotKeyRef?) -> OSStatus {
        RegisterEventHotKey(code, UInt32(cmdKey), EventHotKeyID(signature: 0x54455354, id: code),
                            GetApplicationEventTarget(), OptionBits(kEventHotKeyExclusive), &reference)
    }

    private static func postKey(_ code: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .privateState)
        for pressed in [true, false] {
            let event = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: pressed)
            event?.flags = flags
            event?.post(tap: .cghidEventTap)
        }
    }

    private static func expect(_ condition: Bool, _ message: String) throws {
        if !condition { throw TestFailure(message: message) }
    }
}
