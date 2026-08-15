import Foundation

public enum ScrollDirectionMode: String, CaseIterable, Sendable {
    case natural
    case reversed
}

public enum ScrollInputKind: Sendable {
    case trackpad
    case mouseWheel

    public init(usesContinuousDeltas: Bool) {
        self = usesContinuousDeltas ? .trackpad : .mouseWheel
    }
}

public enum ScrollDirectionDecision {
    public static func shouldReverseEvent(
        systemUsesNaturalDirection: Bool,
        preferredDirection: ScrollDirectionMode
    ) -> Bool {
        switch preferredDirection {
        case .natural:
            return !systemUsesNaturalDirection
        case .reversed:
            return systemUsesNaturalDirection
        }
    }
}
