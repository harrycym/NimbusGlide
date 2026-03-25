import Cocoa
import Carbon

enum HotkeyChoice: String, CaseIterable, Identifiable, Codable {
    case rightOption  = "Right Option ⌥"
    case fn           = "fn Globe 🌐"
    case rightCommand = "Right Command ⌘"
    case custom       = "Custom Key…"

    var id: String { rawValue }

    var keyCode: UInt16 {
        switch self {
        case .rightOption:  return 61   // kVK_RightOption
        case .fn:           return 63   // kVK_Function
        case .rightCommand: return 54   // kVK_RightCommand
        case .custom:       return 0    // placeholder; actual code stored separately
        }
    }

    var modifierFlag: NSEvent.ModifierFlags {
        switch self {
        case .rightOption:  return .option
        case .fn:           return .function
        case .rightCommand: return .command
        case .custom:       return []   // custom uses keyDown events, not flagsChanged
        }
    }
}

class HotkeyManager {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var globalKeyMonitor: Any?
    private var localKeyMonitor: Any?
    private var isKeyDown = false
    private let onKeyDown: () -> Void
    private let onKeyUp: () -> Void
    
    var hotkey: HotkeyChoice {
        didSet {
            isKeyDown = false
            setupMonitors()
            print("[NimbusGlide] Hotkey changed to: \(hotkey.rawValue)")
        }
    }
    var customKeyCode: UInt16 = 0
    
    init(hotkey: HotkeyChoice = .rightOption, onKeyDown: @escaping () -> Void, onKeyUp: @escaping () -> Void) {
        self.hotkey = hotkey
        self.onKeyDown = onKeyDown
        self.onKeyUp = onKeyUp
        setupMonitors()
    }

    deinit { removeMonitors() }
    
    private func removeMonitors() {
        if let monitor = globalMonitor    { NSEvent.removeMonitor(monitor) }
        if let monitor = localMonitor     { NSEvent.removeMonitor(monitor) }
        if let monitor = globalKeyMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = localKeyMonitor  { NSEvent.removeMonitor(monitor) }
        globalMonitor = nil; localMonitor = nil
        globalKeyMonitor = nil; localKeyMonitor = nil
    }

    private func setupMonitors() {
        removeMonitors()
        
        if hotkey == .custom {
            // Listen for regular keyDown/keyUp
            globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
                self?.handleKeyEvent(event)
            }
            localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
                self?.handleKeyEvent(event)
                return event
            }
        } else {
            // Listen for modifier flag changes (Option, Command, fn)
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
                self?.handleFlagsChanged(event)
            }
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
                self?.handleFlagsChanged(event)
                return event
            }
        }

        print("[NimbusGlide] Hotkey listener active: \(hotkey.rawValue)")
    }

    private func handleKeyEvent(_ event: NSEvent) {
        guard event.keyCode == customKeyCode else { return }
        if event.type == .keyDown && !isKeyDown {
            isKeyDown = true
            DispatchQueue.main.async { [weak self] in self?.onKeyDown() }
        } else if event.type == .keyUp && isKeyDown {
            isKeyDown = false
            DispatchQueue.main.async { [weak self] in self?.onKeyUp() }
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let flag = hotkey.modifierFlag
        let flagIsDown = event.modifierFlags.contains(flag)

        if flagIsDown && !isKeyDown {
            if hotkey != .fn && event.keyCode != hotkey.keyCode { return }
            isKeyDown = true
            DispatchQueue.main.async { [weak self] in self?.onKeyDown() }
        } else if !flagIsDown && isKeyDown {
            isKeyDown = false
            DispatchQueue.main.async { [weak self] in self?.onKeyUp() }
        }
    }
}
