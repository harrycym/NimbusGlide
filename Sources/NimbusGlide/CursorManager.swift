import AppKit

class CursorManager {
    private static var micCursor: NSCursor?
    
    static func showMicCursor() {
        let cursor = buildMicCursor()
        cursor.push()
    }
    
    static func restoreCursor() {
        NSCursor.pop()
    }
    
    private static func buildMicCursor() -> NSCursor {
        if let cached = micCursor { return cached }
        
        let size: CGFloat = 32
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            // Draw a circular background
            let circleRect = rect.insetBy(dx: 2, dy: 2)
            NSColor.systemRed.setFill()
            NSBezierPath(ovalIn: circleRect).fill()
            
            // Draw mic SF symbol inside
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .bold)
            if let mic = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: nil)?
                .withSymbolConfiguration(config) {
                mic.isTemplate = true
                NSGraphicsContext.current?.imageInterpolation = .high
                // Tint it white
                NSColor.white.set()
                let micRect = CGRect(
                    x: (size - 16) / 2,
                    y: (size - 16) / 2,
                    width: 16, height: 16
                )
                mic.draw(in: micRect, from: .zero, operation: .sourceAtop, fraction: 1.0)
            }
            return true
        }
        
        // hotspot in center of the circle
        let cursor = NSCursor(image: image, hotSpot: NSPoint(x: size / 2, y: size / 2))
        micCursor = cursor
        return cursor
    }
}
