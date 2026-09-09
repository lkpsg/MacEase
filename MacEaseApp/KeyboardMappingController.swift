import ApplicationServices
@preconcurrency import CoreGraphics
import Foundation

enum KeyboardMappingPreferences {
    static let isEnabledKey = "keyboardMapping.isEnabled"
}

@MainActor
final class KeyboardMappingController {
    static let shared = KeyboardMappingController()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var mapper = KeyboardEventMapper()
    private var isEnabled = false
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isRunning: Bool {
        guard isEnabled, let eventTap else { return false }
        return CGEvent.tapIsEnabled(tap: eventTap)
    }

    @discardableResult
    func reloadPreferences() -> Bool {
        isEnabled = defaults.bool(forKey: KeyboardMappingPreferences.isEnabledKey)
        if isEnabled {
            start()
        } else if !mapper.hasActiveMappings {
            stop()
        }
        // If disabled during a mapped press, keep the tap just long enough to
        // deliver its matching key-up. New presses already pass through.
        return isRunning
    }

    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        for event in mapper.releaseAll() {
            event.post(tap: .cgSessionEventTap)
        }
    }

    private func start() {
        // Checking access does not prompt; the Permissions page owns requests.
        guard AXIsProcessTrusted() else {
            stop()
            return
        }
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: true)
            return
        }

        let mask = CGEventMask((1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue))
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: Self.eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            return
        }
        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func process(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        mapper.process(type: type, event: event, isEnabled: isEnabled)
        if !isEnabled && !mapper.hasActiveMappings {
            stop()
        }
        return Unmanaged.passUnretained(event)
    }

    private nonisolated static let eventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo else { return Unmanaged.passUnretained(event) }
        let controller = Unmanaged<KeyboardMappingController>.fromOpaque(userInfo).takeUnretainedValue()
        return MainActor.assumeIsolated {
            controller.process(type: type, event: event)
        }
    }
}
