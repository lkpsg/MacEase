import AppKit
import ApplicationServices
@preconcurrency import CoreGraphics
import MacEaseCore

/// Optional system integration tests. A child process posts tagged events at
/// the HID entry point. A downstream tap consumes them before app delivery.
@MainActor
final class KeyboardMappingIntegrationTests {
    private nonisolated static let marker: Int64 = 0x4D454B42545354 // MEKBTST

    private struct Key: Codable {
        var code: CGKeyCode
        var down = true
        var flags = CGEventFlags.maskCommand.rawValue
        var repeated = false
    }

    private struct Received {
        let code: Int64
        let type: CGEventType
        let flags: CGEventFlags
        let repeated: Bool
    }

    private var received: [Received] = []

    static func postFixture() throws {
        guard CGPreflightPostEventAccess(),
              let data = Data(base64Encoded: CommandLine.arguments.last ?? "") else {
            throw KeyboardTestFailure(description: "Event-posting access or fixture data is unavailable")
        }
        let keys = try JSONDecoder().decode([Key].self, from: data)
        let source = CGEventSource(stateID: .privateState)
        for key in keys {
            guard let event = CGEvent(keyboardEventSource: source, virtualKey: key.code, keyDown: key.down) else {
                throw KeyboardTestFailure(description: "Unable to create fixture event")
            }
            event.flags = CGEventFlags(rawValue: key.flags)
            event.setIntegerValueField(.eventSourceUserData, value: marker)
            event.setIntegerValueField(.keyboardEventAutorepeat, value: key.repeated ? 1 : 0)
            event.post(tap: .cghidEventTap)
            Thread.sleep(forTimeInterval: 0.02)
        }
    }

    static func run() async throws {
        guard AXIsProcessTrusted(), CGPreflightPostEventAccess() else {
            throw KeyboardTestFailure(description: "--post-key-events requires existing Accessibility and event-posting access")
        }
        let test = KeyboardMappingIntegrationTests()
        let mask = CGEventMask((1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue))
        guard let sink = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .tailAppendEventTap, options: .defaultTap,
            eventsOfInterest: mask, callback: sinkCallback,
            userInfo: Unmanaged.passUnretained(test).toOpaque()
        ), let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, sink, 0) else {
            throw KeyboardTestFailure(description: "Could not install the test event sink")
        }
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: sink, enable: true)
        defer {
            CGEvent.tapEnable(tap: sink, enable: false)
            CFMachPortInvalidate(sink)
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }

        let suite = "com.lkpsg.MacEase.KeyboardMappingTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let controller = KeyboardMappingController(defaults: defaults)
        defer { controller.stop() }

        try expect(!controller.reloadPreferences(), "Mapping must start disabled")
        let original = try await test.send([Key(code: 38), Key(code: 38, down: false)])
        try expect(original.map(\.code) == [38, 38] && original.allSatisfy { $0.flags.contains(.maskCommand) },
                   "Disabled controller altered Command + J")

        defaults.set(true, forKey: KeyboardMappingPreferences.isEnabledKey)
        try expect(controller.reloadPreferences(), "Keyboard mapping event tap failed to start")
        for (input, output): (CGKeyCode, Int64) in [(34, 126), (38, 123), (40, 125), (37, 124)] {
            let result = try await test.send([Key(code: input), Key(code: input, down: false)])
            try expect(result.map(\.code) == [output, output]
                       && result.map(\.type) == [.keyDown, .keyUp]
                       && result.allSatisfy { !$0.flags.contains(.maskCommand) },
                       "Command + key \(input) did not become a complete arrow press in the system stream")
        }
        print("✓ Child-process HID events pass through the actual tap as all four arrow pairs")

        let repeats = try await test.send([
            Key(code: 38), Key(code: 38, repeated: true),
            Key(code: 38, flags: 0, repeated: true), Key(code: 38, down: false, flags: 0),
        ])
        try expect(repeats.map(\.code) == [123, 123, 123, 123]
                   && repeats.map(\.repeated) == [false, true, true, false],
                   "Repeat or early Command release broke the mapped press")
        print("✓ System delivery preserves repeats and early Command release")

        for flags: CGEventFlags in [[], [.maskCommand, .maskShift], [.maskCommand, .maskAlternate],
                                   [.maskCommand, .maskControl], [.maskCommand, .maskSecondaryFn]] {
            let result = try await test.send([
                Key(code: 40, flags: flags.rawValue), Key(code: 40, down: false, flags: flags.rawValue),
            ])
            let modifiers: CGEventFlags = [.maskCommand, .maskShift, .maskControl, .maskAlternate, .maskSecondaryFn]
            try expect(result.map(\.code) == [40, 40]
                       && result.allSatisfy { $0.flags.intersection(modifiers) == flags },
                       "Unmatched modifiers were intercepted in the system stream")
        }
        let lateCommand = try await test.send([
            Key(code: 34, flags: 0), Key(code: 34, repeated: true), Key(code: 34, down: false),
        ])
        try expect(lateCommand.map(\.code) == [34, 34, 34], "Late Command changed an ordinary press")
        print("✓ Other modifier combinations and late Command remain unchanged in the system stream")

        _ = try await test.send([Key(code: 37)])
        defaults.set(false, forKey: KeyboardMappingPreferences.isEnabledKey)
        try expect(!controller.reloadPreferences(), "Disabled state still reports running")
        let release = try await test.send([Key(code: 37, down: false, flags: 0)])
        try expect(release.map(\.code) == [124], "Disabling mid-press lost the arrow key-up")
        let disabled = try await test.send([Key(code: 37), Key(code: 37, down: false)])
        try expect(disabled.map(\.code) == [37, 37], "Disabling did not restore the original shortcut")
        defaults.set(true, forKey: KeyboardMappingPreferences.isEnabledKey)
        try expect(controller.reloadPreferences(), "Re-enabling failed to recreate the tap")
        let restarted = try await test.send([Key(code: 37), Key(code: 37, down: false)])
        try expect(restarted.map(\.code) == [124, 124], "Mapping failed after re-enabling")
        controller.stop()
        try expect(!controller.isRunning, "Stop left the keyboard tap running")
        print("✓ Disabling mid-press, restoring shortcuts, re-enabling and stopping work with macOS")
    }

    private func send(_ keys: [Key]) async throws -> [Received] {
        let start = received.count
        let child = Process()
        child.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
        child.arguments = ["--post-fixture", try JSONEncoder().encode(keys).base64EncodedString()]
        try child.run()
        defer { if child.isRunning { child.terminate() } }
        let deadline = Date().addingTimeInterval(5)
        while (child.isRunning || received.count < start + keys.count) && Date() < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        try Self.expect(!child.isRunning && child.terminationStatus == 0,
                        "Fixture sender failed or timed out")
        try Self.expect(received.count == start + keys.count,
                        "Expected \(keys.count) system events, received \(received.count - start)")
        return Array(received.dropFirst(start))
    }

    private nonisolated static let sinkCallback: CGEventTapCallBack = { _, type, event, userInfo in
        guard event.getIntegerValueField(.eventSourceUserData) == marker, let userInfo else {
            return Unmanaged.passUnretained(event)
        }
        let test = Unmanaged<KeyboardMappingIntegrationTests>.fromOpaque(userInfo).takeUnretainedValue()
        MainActor.assumeIsolated {
            test.received.append(Received(
                code: event.getIntegerValueField(.keyboardEventKeycode), type: type, flags: event.flags,
                repeated: event.getIntegerValueField(.keyboardEventAutorepeat) != 0
            ))
        }
        return nil
    }

    private static func expect(_ condition: Bool, _ message: String) throws {
        if !condition { throw KeyboardTestFailure(description: message) }
    }
}
