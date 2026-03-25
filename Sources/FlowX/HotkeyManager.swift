import Cocoa
import Carbon

enum HotkeyChoice: String, CaseIterable, Identifiable, Codable {
    case rightOption = "Right Option ⌥"
    case fn = "fn Globe 🌐"
    case rightCommand = "Right Command ⌘"
    case rightControl = "Right Control ⌃"

    var id: String { rawValue }

    var keyCode: UInt16 {
        switch self {
        case .rightOption:  return 61   // kVK_RightOption
        case .fn:           return 63   // kVK_Function
        case .rightCommand: return 54   // kVK_RightCommand
        case .rightControl: return 62   // kVK_RightControl
        }
    }

    var modifierFlag: NSEvent.ModifierFlags {
        switch self {
        case .rightOption:  return .option
        case .fn:           return .function
        case .rightCommand: return .command
        case .rightControl: return .control
        }
    }
}

class HotkeyManager {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isKeyDown = false
    private let onKeyDown: () -> Void
    private let onKeyUp: () -> Void
    var hotkey: HotkeyChoice {
        didSet {
            isKeyDown = false
            print("[FlowX] Hotkey changed to: \(hotkey.rawValue)")
        }
    }

    init(hotkey: HotkeyChoice = .rightOption, onKeyDown: @escaping () -> Void, onKeyUp: @escaping () -> Void) {
        self.hotkey = hotkey
        self.onKeyDown = onKeyDown
        self.onKeyUp = onKeyUp
        setupMonitors()
    }

    deinit {
        if let monitor = globalMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = localMonitor { NSEvent.removeMonitor(monitor) }
    }

    private func setupMonitors() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }

        print("[FlowX] Hotkey listener active: \(hotkey.rawValue)")
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let flag = hotkey.modifierFlag
        let flagIsDown = event.modifierFlags.contains(flag)

        if flagIsDown && !isKeyDown {
            // For non-fn keys, also verify keyCode to distinguish left/right
            if hotkey != .fn && event.keyCode != hotkey.keyCode {
                return
            }
            isKeyDown = true
            DispatchQueue.main.async { [weak self] in
                self?.onKeyDown()
            }
        } else if !flagIsDown && isKeyDown {
            isKeyDown = false
            DispatchQueue.main.async { [weak self] in
                self?.onKeyUp()
            }
        }
    }
}
