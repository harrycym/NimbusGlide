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

    // Deep purple to indigo gradient
    let colors = [
        CGColor(red: 0.25, green: 0.10, blue: 0.55, alpha: 1.0),
        CGColor(red: 0.10, green: 0.05, blue: 0.35, alpha: 1.0),
    ]
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                               colors: colors as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size),
                           end: CGPoint(x: size, y: 0), options: [])
    ctx.restoreGState()

    // Draw waveform bars in the center
    let barCount = 5
    let centerY = size * 0.5
    let totalWidth = size * 0.50
    let barWidth = totalWidth / CGFloat(barCount * 2 - 1)
    let startX = (size - totalWidth) / 2.0

    let barHeights: [CGFloat] = [0.18, 0.35, 0.50, 0.35, 0.18]

    for i in 0..<barCount {
        let x = startX + CGFloat(i) * barWidth * 2
        let h = size * barHeights[i]
        let y = centerY - h / 2

        let barRect = CGRect(x: x, y: y, width: barWidth, height: h)
        let barPath = CGPath(roundedRect: barRect, cornerWidth: barWidth / 2,
                             cornerHeight: barWidth / 2, transform: nil)

        // White bars with slight glow
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: size * 0.03,
                      color: CGColor(red: 0.6, green: 0.5, blue: 1.0, alpha: 0.8))
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
        ctx.addPath(barPath)
        ctx.fillPath()
        ctx.restoreGState()
    }

    image.unlockFocus()
    return image
}

generateIcon()
