import AppKit
@preconcurrency import CoreGraphics
import MacEaseCore

enum ScrollDirectionPreferences {
    static let isEnabledKey = "scrollDirection.isEnabled"
    static let trackpadModeKey = "scrollDirection.trackpadMode"
    static let mouseModeKey = "scrollDirection.mouseMode"

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: isEnabledKey)
    }

    static var trackpadMode: ScrollDirectionMode {
        mode(forKey: trackpadModeKey, default: .natural)
    }

    static var mouseMode: ScrollDirectionMode {
        mode(forKey: mouseModeKey, default: .reversed)
    }

    private static func mode(
        forKey key: String,
        default defaultMode: ScrollDirectionMode
    ) -> ScrollDirectionMode {
        guard let rawValue = UserDefaults.standard.string(forKey: key) else {
            return defaultMode
        }
        return ScrollDirectionMode(rawValue: rawValue) ?? defaultMode
    }
}

@MainActor
final class ScrollDirectionController {
    static let shared = ScrollDirectionController()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var trackpadMode = ScrollDirectionMode.natural
    private var mouseMode = ScrollDirectionMode.reversed
    private(set) var failedToStart = false

    private init() {}

    var isRunning: Bool {
        eventTap != nil
    }

    @discardableResult
    func reloadPreferences() -> Bool {
        trackpadMode = ScrollDirectionPreferences.trackpadMode
        mouseMode = ScrollDirectionPreferences.mouseMode

        if ScrollDirectionPreferences.isEnabled {
            start()
        } else {
            stop()
            failedToStart = false
        }

        return isRunning
    }

    private func start() {
        guard eventTap == nil else {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return
        }

        let eventMask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
        let controllerPointer = Unmanaged.passUnretained(self).toOpaque()
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: Self.eventTapCallback,
            userInfo: controllerPointer
        ) else {
            failedToStart = true
            return
        }

        guard let runLoopSource = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault,
            eventTap,
            0
        ) else {
            failedToStart = true
            return
        }

        self.eventTap = eventTap
        self.runLoopSource = runLoopSource
        failedToStart = false
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    private func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    private func process(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .scrollWheel,
              ScrollDirectionPreferences.isEnabled,
              let appKitEvent = NSEvent(cgEvent: event) else {
            return Unmanaged.passUnretained(event)
        }

        let inputKind = ScrollInputKind(
            usesContinuousDeltas: event.getIntegerValueField(
                .scrollWheelEventIsContinuous
            ) != 0
        )
        let preferredDirection: ScrollDirectionMode
        switch inputKind {
        case .trackpad:
            preferredDirection = trackpadMode
        case .mouseWheel:
            preferredDirection = mouseMode
        }

        guard ScrollDirectionDecision.shouldReverseEvent(
            systemUsesNaturalDirection: appKitEvent.isDirectionInvertedFromDevice,
            preferredDirection: preferredDirection
        ) else {
            return Unmanaged.passUnretained(event)
        }

        reverseDeltas(in: event)
        return Unmanaged.passUnretained(event)
    }

    private func reverseDeltas(in event: CGEvent) {
        let deltaFields: [CGEventField] = [
            .scrollWheelEventDeltaAxis1,
            .scrollWheelEventDeltaAxis2,
            .scrollWheelEventDeltaAxis3,
        ]
        let pointFields: [CGEventField] = [
            .scrollWheelEventPointDeltaAxis1,
            .scrollWheelEventPointDeltaAxis2,
            .scrollWheelEventPointDeltaAxis3,
        ]
        let fixedPointFields: [CGEventField] = [
            .scrollWheelEventFixedPtDeltaAxis1,
            .scrollWheelEventFixedPtDeltaAxis2,
            .scrollWheelEventFixedPtDeltaAxis3,
        ]

        // Snapshot every representation before writing. Core Graphics updates
        // the point and fixed-point fields as a side effect of setting the
        // coarse delta, so reading fields one at a time would corrupt later
        // values. Point values are deliberately restored last.
        let deltaValues = deltaFields.map(event.getIntegerValueField)
        let pointValues = pointFields.map(event.getIntegerValueField)
        let fixedPointValues = fixedPointFields.map(event.getDoubleValueField)

        for (field, value) in zip(deltaFields, deltaValues) {
            event.setIntegerValueField(
                field,
                value: -value
            )
        }
        for (field, value) in zip(fixedPointFields, fixedPointValues) {
            event.setDoubleValueField(
                field,
                value: -value
            )
        }
        for (field, value) in zip(pointFields, pointValues) {
            event.setIntegerValueField(
                field,
                value: -value
            )
        }
    }

    private nonisolated static let eventTapCallback: CGEventTapCallBack = {
        _, type, event, userInfo in
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }

        let controller = Unmanaged<ScrollDirectionController>
            .fromOpaque(userInfo)
            .takeUnretainedValue()
        return MainActor.assumeIsolated {
            controller.process(type: type, event: event)
        }
    }
}
