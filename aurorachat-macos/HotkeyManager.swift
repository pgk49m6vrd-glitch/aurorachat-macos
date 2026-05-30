import Cocoa
import Carbon

// global hotkey to summon the app
// default is opt+space, can be changed in settings
@MainActor
final class HotkeyManager {
    static let shared = HotkeyManager()

    private var globalMonitor: Any?
    private var localMonitor: Any?

    /// The current hotkey configuration
    var modifierFlags: NSEvent.ModifierFlags {
        didSet { saveAndRestart() }
    }
    var keyCode: UInt16 {
        didSet { saveAndRestart() }
    }

    // MARK: - Storage Keys

    private static let modifierKey = "hotkeyModifier"
    private static let keyCodeKey = "hotkeyKeyCode"
    private static let enabledKey = "hotkeyEnabled"

    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
            if isEnabled { start() } else { stop() }
        }
    }

    // MARK: - Init

    private init() {
        let savedModifier = UserDefaults.standard.object(forKey: Self.modifierKey) as? UInt ?? NSEvent.ModifierFlags.option.rawValue
        let savedKeyCode = UserDefaults.standard.object(forKey: Self.keyCodeKey) as? UInt16 ?? 49 // 49 = Space
        let savedEnabled = UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true

        self.modifierFlags = NSEvent.ModifierFlags(rawValue: savedModifier)
        self.keyCode = savedKeyCode
        self.isEnabled = savedEnabled
    }

    // MARK: - Start / Stop

    func start() {
        guard isEnabled else { return }
        stop() // Clear existing monitors

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.matchesHotkey(event) == true {
                self?.bringWindowToFront()
                return nil // Consume the event
            }
            return event
        }
    }

    func stop() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    // MARK: - Event Handling

    private func handleKeyEvent(_ event: NSEvent) {
        guard matchesHotkey(event) else { return }
        Task { @MainActor in
            bringWindowToFront()
        }
    }

    private func matchesHotkey(_ event: NSEvent) -> Bool {
        let masked = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return event.keyCode == keyCode && masked == modifierFlags
    }

    private func bringWindowToFront() {
        NSApp.activate(ignoringOtherApps: true)
        // find a visible window, or just grab the first one
        if let win = NSApp.windows.first(where: { $0.isVisible }) {
            win.makeKeyAndOrderFront(nil)
        } else if let win = NSApp.windows.first {
            win.makeKeyAndOrderFront(nil)
        }
    }

    // MARK: - Persistence

    private func saveAndRestart() {
        UserDefaults.standard.set(modifierFlags.rawValue, forKey: Self.modifierKey)
        UserDefaults.standard.set(keyCode, forKey: Self.keyCodeKey)
        if isEnabled {
            start()
        }
    }

    /// readable label for the shortcut (shown in settings)
    var shortcutLabel: String {
        var parts: [String] = []
        if modifierFlags.contains(.control) { parts.append("⌃") }
        if modifierFlags.contains(.option) { parts.append("⌥") }
        if modifierFlags.contains(.shift) { parts.append("⇧") }
        if modifierFlags.contains(.command) { parts.append("⌘") }
        parts.append(keyName(for: keyCode))
        return parts.joined()
    }

    private func keyName(for code: UInt16) -> String {
        switch code {
        case 49: return "Space"
        case 36: return "Return"
        case 48: return "Tab"
        case 53: return "Esc"
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 5: return "G"
        case 4: return "H"
        case 38: return "J"
        case 40: return "K"
        case 37: return "L"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 45: return "N"
        case 46: return "M"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 17: return "T"
        case 16: return "Y"
        case 32: return "U"
        case 34: return "I"
        case 31: return "O"
        case 35: return "P"
        default: return "Key(\(code))"
        }
    }
}
