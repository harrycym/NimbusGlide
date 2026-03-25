#!/usr/bin/env swift

import AppKit

// Generate a FlowX app icon using Core Graphics
func generateIcon() {
    let sizes: [(CGFloat, String)] = [
        (16, "icon_16x16"),
        (32, "icon_16x16@2x"),
        (32, "icon_32x32"),
        (64, "icon_32x32@2x"),
        (128, "icon_128x128"),
        (256, "icon_128x128@2x"),
        (256, "icon_256x256"),
        (512, "icon_256x256@2x"),
        (512, "icon_512x512"),
        (1024, "icon_512x512@2x"),
    ]

    let iconsetPath = "/tmp/FlowX.iconset"
    let fm = FileManager.default
    try? fm.removeItem(atPath: iconsetPath)
    try! fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

    for (size, name) in sizes {
        let image = renderIcon(size: size)
        let pngData = image.tiffRepresentation.flatMap {
            NSBitmapImageRep(data: $0)?.representation(using: .png, properties: [:])
        }
        let path = "\(iconsetPath)/\(name).png"
        try! pngData!.write(to: URL(fileURLWithPath: path))
    }

    // Convert iconset to icns
    let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/AppIcon.icns"
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    process.arguments = ["-c", "icns", iconsetPath, "-o", outputPath]
    try! process.run()
    process.waitUntilExit()

    try? fm.removeItem(atPath: iconsetPath)
    print("Icon generated: \(outputPath)")
}

func renderIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let ctx = NSGraphicsContext.current!.cgContext
    let rect = CGRect(x: 0, y: 0, width: size, height: size)

    // Background: rounded rectangle with gradient
    let cornerRadius = size * 0.22
    let bgPath = CGPath(roundedRect: rect.insetBy(dx: size * 0.02, dy: size * 0.02),
                        cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()

    // Dark cinematic gradient for a premium commercial look
    let colors = [
        CGColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1.0),
        CGColor(red: 0.20, green: 0.05, blue: 0.40, alpha: 1.0),
    ]
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                               colors: colors as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size),
                           end: CGPoint(x: size, y: 0), options: [])
    ctx.restoreGState()

    // Helper to draw a single 7-bar waveform
    func drawWaveform(context: CGContext, canvasSize: CGFloat, alpha: CGFloat) {
        let barCount = 7
        let centerY = canvasSize * 0.5
        let totalWidth = canvasSize * 0.65
        let barWidth = totalWidth / CGFloat(barCount * 2 - 1)
        let startX = (canvasSize - totalWidth) / 2.0
        
        let barHeights: [CGFloat] = [0.2, 0.4, 0.6, 0.8, 0.6, 0.4, 0.2]
        
        for i in 0..<barCount {
            let x = startX + CGFloat(i) * barWidth * 2
            let h = canvasSize * barHeights[i]
            let y = centerY - h / 2
            let barRect = CGRect(x: x, y: y, width: barWidth, height: h)
            let barPath = CGPath(roundedRect: barRect, cornerWidth: barWidth / 2, cornerHeight: barWidth / 2, transform: nil)
            
            context.saveGState()
            context.setShadow(offset: .zero, blur: canvasSize * 0.04, color: CGColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 0.8))
            context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: alpha))
            context.addPath(barPath)
            context.fillPath()
            context.restoreGState()
        }
    }

    // Draw two intersecting waveforms to form the "X"
    ctx.saveGState()
    ctx.translateBy(x: size / 2, y: size / 2)
    ctx.rotate(by: .pi / 4) // 45 degrees
    ctx.translateBy(x: -size / 2, y: -size / 2)
    drawWaveform(context: ctx, canvasSize: size, alpha: 0.75)
    ctx.restoreGState()
    
    ctx.saveGState()
    ctx.translateBy(x: size / 2, y: size / 2)
    ctx.rotate(by: -.pi / 4) // -45 degrees
    ctx.translateBy(x: -size / 2, y: -size / 2)
    drawWaveform(context: ctx, canvasSize: size, alpha: 0.95)
    ctx.restoreGState()

    image.unlockFocus()
    return image
}

generateIcon()
