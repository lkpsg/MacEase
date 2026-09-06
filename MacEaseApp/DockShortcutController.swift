import AppKit
import Carbon
import Combine
import MacEaseCore

enum DockShortcutPreferences {
    static let isEnabledKey = "dockShortcutsEnabled"
    static let includesFinderKey = "dockShortcutsIncludeFinder"
}

@MainActor
final class DockShortcutController: ObservableObject {
    static let shared = DockShortcutController()

    @Published private(set) var shortcuts: [DockShortcut] = []
    @Published private(set) var unavailablePositions: Set<Int> = []
    @Published private(set) var failedToStart = false
    @Published private(set) var launchError: String?

    private var hotKeys: [Int: EventHotKeyRef] = [:]
    private var eventHandler: EventHandlerRef?
    private var refreshTimer: Timer?
    private var pressedPositions: Set<Int> = []
    private static let signature: OSType = 0x4D45444B // MEDK

    // Injectable Dock reader and launcher also let the integration tests use
    // real global key events without changing the user's Dock or opening apps.
    private let defaults: UserDefaults
    private let readApplications: @MainActor (Bool) -> [DockApplication]
    private let launchApplication: (@MainActor (URL) -> Void)?

    init(
        defaults: UserDefaults = .standard,
        readApplications: @escaping @MainActor (Bool) -> [DockApplication] = DockShortcutController.readDockApplications,
        launchApplication: (@MainActor (URL) -> Void)? = nil
    ) {
        self.defaults = defaults
        self.readApplications = readApplications
        self.launchApplication = launchApplication
    }

    func reloadPreferences() {
        let applications = readApplications(defaults.bool(forKey: DockShortcutPreferences.includesFinderKey))
        let updated = DockShortcut.make(applications: applications)
        if shortcuts != updated {
            shortcuts = updated
        }

        guard defaults.bool(forKey: DockShortcutPreferences.isEnabledKey) else {
            stop()
            return
        }

        if refreshTimer == nil {
            let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.reloadPreferences()
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            refreshTimer = timer
        }

        guard installEventHandler() else {
            failedToStart = true
            return
        }
        if failedToStart { failedToStart = false }

        let desiredPositions = Set(shortcuts.map(\.position))
        for position in Array(hotKeys.keys) where !desiredPositions.contains(position) {
            if let reference = hotKeys.removeValue(forKey: position) {
                UnregisterEventHotKey(reference)
            }
            pressedPositions.remove(position)
        }

        var unavailable: Set<Int> = []
        for shortcut in shortcuts where hotKeys[shortcut.position] == nil {
            var reference: EventHotKeyRef?
            let status = RegisterEventHotKey(
                shortcut.keyCode,
                UInt32(cmdKey),
                EventHotKeyID(signature: Self.signature, id: UInt32(shortcut.position)),
                GetApplicationEventTarget(),
                OptionBits(kEventHotKeyExclusive),
                &reference
            )
            if status == noErr, let reference {
                hotKeys[shortcut.position] = reference
            } else {
                unavailable.insert(shortcut.position)
            }
        }
        if unavailablePositions != unavailable {
            unavailablePositions = unavailable
        }
    }

    func stop() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        hotKeys.values.forEach { UnregisterEventHotKey($0) }
        hotKeys.removeAll()
        pressedPositions.removeAll()
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
        eventHandler = nil
        if !unavailablePositions.isEmpty { unavailablePositions = [] }
        if failedToStart { failedToStart = false }
        if launchError != nil { launchError = nil }
    }

    static func readDockApplications(includesFinder: Bool) -> [DockApplication] {
        let domain = "com.apple.dock" as CFString
        CFPreferencesAppSynchronize(domain)
        let tiles = CFPreferencesCopyAppValue("persistent-apps" as CFString, domain)
            as? [[String: Any]] ?? []
        return DockApplicationParser.applications(from: tiles, includesFinder: includesFinder)
    }

    private func installEventHandler() -> Bool {
        guard eventHandler == nil else { return true }
        let events = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased)),
        ]
        return InstallEventHandler(
            GetApplicationEventTarget(),
            Self.hotKeyHandler,
            events.count,
            events,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        ) == noErr
    }

    private func handleHotKey(position: Int, isPressed: Bool) {
        guard isPressed else {
            pressedPositions.remove(position)
            return
        }
        guard !pressedPositions.contains(position) else { return }

        // Read the current Dock at dispatch time too, so a reorder immediately
        // followed by a shortcut cannot launch the app at the previous position.
        reloadPreferences()
        guard hotKeys[position] != nil,
              let shortcut = shortcuts.first(where: { $0.position == position }) else {
            return
        }
        pressedPositions.insert(position)
        launchError = nil
        if let launchApplication {
            launchApplication(shortcut.application.url)
        } else {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            NSWorkspace.shared.openApplication(at: shortcut.application.url, configuration: configuration) { [weak self] _, error in
                guard let error else { return }
                let message = error.localizedDescription
                Task { @MainActor in
                    self?.launchError = message
                    NSSound.beep()
                }
            }
        }
    }

    private nonisolated static let hotKeyHandler: EventHandlerUPP = { _, event, userData in
        guard let event, let userData else { return OSStatus(eventNotHandledErr) }
        var identifier = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &identifier
        )
        guard status == noErr else { return status }
        let controller = Unmanaged<DockShortcutController>.fromOpaque(userData).takeUnretainedValue()
        let isPressed = GetEventKind(event) == UInt32(kEventHotKeyPressed)
        return MainActor.assumeIsolated {
            guard identifier.signature == DockShortcutController.signature else { return OSStatus(eventNotHandledErr) }
            controller.handleHotKey(
                position: Int(identifier.id),
                isPressed: isPressed
            )
            return noErr
        }
    }
}
