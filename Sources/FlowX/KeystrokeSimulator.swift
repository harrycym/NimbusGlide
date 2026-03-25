import AppKit
import CoreGraphics

class KeystrokeSimulator {
    /// Pastes the given text into the frontmost application by:
    /// 1. Saving the current clipboard contents
    /// 2. Copying the new text to the clipboard
    /// 3. Simulating Cmd+V
    /// 4. Restoring the original clipboard after a short delay
    func pasteText(_ text: String) {
        let pasteboard = NSPasteboard.general

        // Save current clipboard
        let oldContents = pasteboard.string(forType: .string)

        // Set new text
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Small delay to ensure pasteboard is ready
        usleep(50_000) // 50ms

        // Simulate Cmd+V
        simulateCmdV()

        // Restore original clipboard after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            pasteboard.clearContents()
            if let old = oldContents {
                pasteboard.setString(old, forType: .string)
            }
        }
    }

    private func simulateCmdV() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Key code 9 = 'V'
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)

        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
