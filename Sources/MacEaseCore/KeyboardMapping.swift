/// Physical ANSI I/J/K/L keys, independent of the active input source.
public enum KeyboardMapping: String, CaseIterable, Identifiable, Sendable {
    case up, left, down, right

    public var id: String { rawValue }

    public var sourceLabel: String {
        switch self {
        case .up: "⌘I"
        case .left: "⌘J"
        case .down: "⌘K"
        case .right: "⌘L"
        }
    }

    public var sourceKeyCode: UInt16 {
        switch self {
        case .up: 34
        case .left: 38
        case .down: 40
        case .right: 37
        }
    }

    public var destinationKeyCode: UInt16 {
        switch self {
        case .up: 126
        case .left: 123
        case .down: 125
        case .right: 124
        }
    }

    public var arrow: String {
        switch self {
        case .up: "↑"
        case .left: "←"
        case .down: "↓"
        case .right: "→"
        }
    }

    public var functionCharacter: UInt16 {
        switch self {
        case .up: 0xF700
        case .left: 0xF702
        case .down: 0xF701
        case .right: 0xF703
        }
    }
}
