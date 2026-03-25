import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var memoryManager: MemoryManager
    @EnvironmentObject var updateChecker: UpdateChecker
    @EnvironmentObject var pipelineState: PipelineState
    @EnvironmentObject var usageTracker: UsageTracker

    var body: some View {
        AppSettingsView()
            .environmentObject(settingsManager)
            .environmentObject(pipelineState)
            .environmentObject(usageTracker)
            .environmentObject(updateChecker)
            .frame(width: 420, height: 500)
    }
}
