import SwiftUI
import AppKit

@main
struct FlowXApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("FlowX", id: "main") {
            MainWindowView()
                .environmentObject(appDelegate.pipelineState)
                .environmentObject(appDelegate.profileManager)
                .environmentObject(appDelegate.memoryManager)
                .environmentObject(appDelegate.settingsManager)
                .environmentObject(appDelegate.updateChecker)
                .environmentObject(appDelegate.usageTracker)
        }
        .defaultSize(width: 700, height: 480)

        Settings {
            SettingsView()
                .environmentObject(appDelegate.profileManager)
                .environmentObject(appDelegate.memoryManager)
                .environmentObject(appDelegate.settingsManager)
                .environmentObject(appDelegate.updateChecker)
        }
    }
}
