import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var memoryManager: MemoryManager
    @EnvironmentObject var updateChecker: UpdateChecker

    var body: some View {
        AppSettingsView()
            .environmentObject(settingsManager)
            .environmentObject(profileManager)
            .environmentObject(memoryManager)
            .environmentObject(updateChecker)
            .frame(width: 420, height: 500)
    }
}
