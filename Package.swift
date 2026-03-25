// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FlowX",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "FlowX",
            path: "Sources/FlowX",
            resources: [
                .copy("../../Resources")
            ],
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("Carbon"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        )
    ]
)
