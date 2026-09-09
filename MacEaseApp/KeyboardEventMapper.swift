@preconcurrency import CoreGraphics
import MacEaseCore

/// Keeps each physical press paired with the same output through repeats and
/// release, even if Command is released or the feature is disabled first.
struct KeyboardEventMapper {
    private enum Press {
        case passthrough
        case mapped(KeyboardMapping)
    }

    private var pressedKeys: [CGKeyCode: Press] = [:]

    var hasActiveMappings: Bool {
        pressedKeys.values.contains { if case .mapped = $0 { true } else { false } }
    }

    mutating func process(type: CGEventType, event: CGEvent, isEnabled: Bool) {
        guard type == .keyDown || type == .keyUp,
              let keyCode = CGKeyCode(exactly: event.getIntegerValueField(.keyboardEventKeycode)),
              let mapping = KeyboardMapping.allCases.first(where: { $0.sourceKeyCode == keyCode }) else {
            return
        }

        let press: Press?
        if type == .keyUp {
            press = pressedKeys.removeValue(forKey: keyCode)
        } else if event.getIntegerValueField(.keyboardEventAutorepeat) != 0 {
            // Never start mapping halfway through an ordinary letter press.
            press = pressedKeys[keyCode]
        } else {
            let modifiers = event.flags.intersection([
                .maskCommand, .maskShift, .maskControl, .maskAlternate, .maskSecondaryFn,
            ])
            let newPress: Press = isEnabled && modifiers == .maskCommand
                ? .mapped(mapping) : .passthrough
            pressedKeys[keyCode] = newPress
            press = newPress
        }

        if case .mapped(let destination) = press {
            Self.apply(destination, to: event)
        }
    }

    mutating func releaseAll() -> [CGEvent] {
        defer { pressedKeys.removeAll() }
        return pressedKeys.values.compactMap { press in
            guard case .mapped(let mapping) = press,
                  let event = CGEvent(keyboardEventSource: nil,
                                      virtualKey: mapping.destinationKeyCode, keyDown: false) else {
                return nil
            }
            Self.apply(mapping, to: event)
            return event
        }
    }

    private static func apply(_ mapping: KeyboardMapping, to event: CGEvent) {
        event.setIntegerValueField(.keyboardEventKeycode, value: Int64(mapping.destinationKeyCode))
        // Strip both generic and device-specific Command bits. Native arrows
        // carry the numeric-pad and function flags, and no text modifiers.
        event.flags = event.flags.intersection([.maskAlphaShift, .maskNonCoalesced])
            .union([.maskNumericPad, .maskSecondaryFn])
        var character = mapping.functionCharacter
        event.keyboardSetUnicodeString(stringLength: 1, unicodeString: &character)
    }
}
