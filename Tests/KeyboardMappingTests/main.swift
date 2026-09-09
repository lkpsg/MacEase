import AppKit
import MacEaseCore

struct KeyboardTestFailure: Error, CustomStringConvertible {
    let description: String
}

@main
@MainActor
enum KeyboardMappingTests {
    static func main() throws {
        if CommandLine.arguments.contains("--post-fixture") {
            try KeyboardMappingIntegrationTests.postFixture()
            return
        }
        _ = NSApplication.shared
        try testArrowEvents()
        try testPassthrough()
        try testPressLifetime()
        try testLateCommand()
        try testMultipleKeysAndCleanup()
        try testTextNavigation()
        if CommandLine.arguments.contains("--post-key-events") {
            Task { @MainActor in
                do {
                    try await KeyboardMappingIntegrationTests.run()
                    print("✅ Keyboard mapping and system event integration tests passed")
                    exit(0)
                } catch {
                    print("✗ \(error)")
                    exit(1)
                }
            }
            NSApplication.shared.run()
        } else {
            print("✅ Keyboard mapping tests passed")
        }
    }

    private static func testArrowEvents() throws {
        let fixtures: [(CGKeyCode, CGKeyCode, String)] = [
            (34, 126, "\u{F700}"), (38, 123, "\u{F702}"),
            (40, 125, "\u{F701}"), (37, 124, "\u{F703}"),
        ]
        // Include left/right device-specific Command flags and Caps Lock.
        for commandFlags in [CGEventFlags.maskCommand, CGEventFlags(rawValue: 0x100008),
                             CGEventFlags(rawValue: 0x100010), [.maskCommand, .maskAlphaShift]] {
            for (input, output, character) in fixtures {
                var mapper = KeyboardEventMapper()
                for type in [CGEventType.keyDown, .keyUp] {
                    let event = makeEvent(input, type: type, flags: commandFlags)
                    event.timestamp = 123456789
                    mapper.process(type: type, event: event, isEnabled: true)
                    let native = try nativeEvent(event)
                    try expect(native.keyCode == output, "Incorrect arrow for key \(input)")
                    try expect(native.characters == character, "Original letter leaked into arrow event")
                    try expect(!native.modifierFlags.contains(.command) && event.flags.rawValue & 0x18 == 0,
                               "Command flags must be removed, including device-specific flags")
                    try expect(event.flags.contains(.maskAlphaShift) == commandFlags.contains(.maskAlphaShift),
                               "Caps Lock state must survive")
                    try expect(event.timestamp == 123456789 && event.type == type, "Event timing/type changed")
                }
                try expect(!mapper.hasActiveMappings, "Key-up must clear active mapping")
            }
        }
        print("✓ All four arrows have native key codes, characters and modifiers")
    }

    private static func testPassthrough() throws {
        let flags: [CGEventFlags] = [[], .maskShift, .maskAlternate, .maskControl,
                                     [.maskCommand, .maskShift], [.maskCommand, .maskAlternate],
                                     [.maskCommand, .maskControl], [.maskCommand, .maskSecondaryFn]]
        for mapping in KeyboardMapping.allCases {
            for modifiers in flags {
                var mapper = KeyboardEventMapper()
                let event = makeEvent(mapping.sourceKeyCode, flags: modifiers)
                mapper.process(type: .keyDown, event: event, isEnabled: true)
                try expect(event.getIntegerValueField(.keyboardEventKeycode) == mapping.sourceKeyCode
                           && event.flags == modifiers, "Unmatched shortcut was changed")
            }
            var disabled = KeyboardEventMapper()
            let event = makeEvent(mapping.sourceKeyCode)
            disabled.process(type: .keyDown, event: event, isEnabled: false)
            try expect(event.getIntegerValueField(.keyboardEventKeycode) == mapping.sourceKeyCode,
                       "Disabled feature intercepted a shortcut")
        }
        var mapper = KeyboardEventMapper()
        let other = makeEvent(0) // Command + A
        mapper.process(type: .keyDown, event: other, isEnabled: true)
        try expect(other.getIntegerValueField(.keyboardEventKeycode) == 0 && other.flags == .maskCommand,
                   "Unrelated key was changed")
        print("✓ Ordinary typing, other shortcuts and disabled mappings pass through")
    }

    private static func testPressLifetime() throws {
        var mapper = KeyboardEventMapper()
        let down = makeEvent(38)
        mapper.process(type: .keyDown, event: down, isEnabled: true)
        for enabled in [true, false] {
            let repeated = makeEvent(38, flags: [], repeated: true)
            mapper.process(type: .keyDown, event: repeated, isEnabled: enabled)
            try expect(repeated.getIntegerValueField(.keyboardEventKeycode) == 123
                       && repeated.getIntegerValueField(.keyboardEventAutorepeat) == 1,
                       "Holding a mapped key must keep producing repeat arrows")
        }
        let newPress = makeEvent(40)
        mapper.process(type: .keyDown, event: newPress, isEnabled: false)
        try expect(newPress.getIntegerValueField(.keyboardEventKeycode) == 40,
                   "Disabling must stop mapping new presses immediately")
        let up = makeEvent(38, type: .keyUp, flags: [])
        mapper.process(type: .keyUp, event: up, isEnabled: false)
        try expect(up.getIntegerValueField(.keyboardEventKeycode) == 123 && !mapper.hasActiveMappings,
                   "Release must match the arrow even after Command release or disabling")
        let plain = makeEvent(38, flags: [])
        mapper.process(type: .keyDown, event: plain, isEnabled: true)
        try expect(plain.getIntegerValueField(.keyboardEventKeycode) == 38, "Mapping leaked into next press")
        print("✓ Repeats and key-up stay paired across Command release and disabling")
    }

    private static func testLateCommand() throws {
        for initiallyEnabled in [true, false] {
            var mapper = KeyboardEventMapper()
            let plain = makeEvent(34, flags: initiallyEnabled ? [] : .maskCommand)
            mapper.process(type: .keyDown, event: plain, isEnabled: initiallyEnabled)
            for type in [CGEventType.keyDown, .keyUp] {
                let event = makeEvent(34, type: type, repeated: type == .keyDown)
                mapper.process(type: type, event: event, isEnabled: true)
                try expect(event.getIntegerValueField(.keyboardEventKeycode) == 34,
                           "Pressing Command or enabling mid-press must not create an unmatched arrow")
            }
        }
        var fresh = KeyboardEventMapper()
        let orphan = makeEvent(37, repeated: true)
        fresh.process(type: .keyDown, event: orphan, isEnabled: true)
        try expect(orphan.getIntegerValueField(.keyboardEventKeycode) == 37, "Orphan repeat was mapped")
        print("✓ Mid-press modifier/preference changes never begin a new mapping")
    }

    private static func testMultipleKeysAndCleanup() throws {
        var mapper = KeyboardEventMapper()
        for key: CGKeyCode in [34, 37] {
            mapper.process(type: .keyDown, event: makeEvent(key), isEnabled: true)
        }
        let up = makeEvent(34, type: .keyUp)
        mapper.process(type: .keyUp, event: up, isEnabled: true)
        try expect(mapper.hasActiveMappings, "Releasing I must not clear held L")
        let releases = mapper.releaseAll()
        try expect(releases.count == 1 && releases[0].type == .keyUp
                   && releases[0].getIntegerValueField(.keyboardEventKeycode) == 124,
                   "Stopping must release exactly the remaining mapped arrow")
        try expect(!mapper.hasActiveMappings && mapper.releaseAll().isEmpty, "Cleanup must be idempotent")
        print("✓ Simultaneous keys and shutdown release each arrow correctly")
    }

    private static func testTextNavigation() throws {
        let fixtures: [(CGKeyCode, Int)] = [(34, 1), (38, 4), (40, 9), (37, 6)]
        for (key, destination) in fixtures {
            let text = NSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
            text.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
            text.string = "abc\ndef\nghi"
            text.setSelectedRange(NSRange(location: 5, length: 0))
            var mapper = KeyboardEventMapper()
            let event = makeEvent(key)
            mapper.process(type: .keyDown, event: event, isEnabled: true)
            text.keyDown(with: try nativeEvent(event))
            try expect(text.selectedRange() == NSRange(location: destination, length: 0),
                       "Mapped key \(key) moved to \(text.selectedRange()) instead of \(destination)")
            try expect(text.string == "abc\ndef\nghi", "Arrow inserted or modified text")
        }
        print("✓ NSTextView moves one position in all four directions without inserting letters")
    }

    private static func makeEvent(_ key: CGKeyCode, type: CGEventType = .keyDown,
                                  flags: CGEventFlags = .maskCommand, repeated: Bool = false) -> CGEvent {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: type == .keyDown)!
        event.flags = flags
        event.setIntegerValueField(.keyboardEventAutorepeat, value: repeated ? 1 : 0)
        // Force the original letter into the payload to catch stale Unicode.
        var letter: UniChar = 0x0069
        event.keyboardSetUnicodeString(stringLength: 1, unicodeString: &letter)
        return event
    }

    private static func nativeEvent(_ event: CGEvent) throws -> NSEvent {
        guard let native = NSEvent(cgEvent: event) else {
            throw KeyboardTestFailure(description: "Could not create AppKit event")
        }
        return native
    }

    private static func expect(_ condition: Bool, _ message: String) throws {
        if !condition { throw KeyboardTestFailure(description: message) }
    }
}
