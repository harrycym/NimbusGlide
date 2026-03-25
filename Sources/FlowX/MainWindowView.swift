import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case home = "Home"
    case profiles = "Profiles"
    case history = "History"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .profiles: return "person.2.fill"
        case .history: return "clock.fill"
        case .settings: return "gear"
        }
    }
}

struct MainWindowView: View {
    @EnvironmentObject var pipelineState: PipelineState
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var memoryManager: MemoryManager
    @EnvironmentObject var settingsManager: SettingsManager

    @State private var selectedItem: SidebarItem = .home
    @AppStorage("flowx_onboarding_complete") private var hasCompletedOnboarding = false

    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView(isComplete: $hasCompletedOnboarding)
                .environmentObject(settingsManager)
                .environmentObject(pipelineState)
                .environmentObject(profileManager)
        } else {
            NavigationSplitView {
                sidebar
            } detail: {
                detail
            }
            .frame(minWidth: 650, minHeight: 450)
        }
    }

    private var sidebar: some View {
        List(SidebarItem.allCases, selection: $selectedItem) { item in
            Label(item.rawValue, systemImage: item.icon)
                .tag(item)
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            StatusPill(status: pipelineState.status)
                .padding(12)
        }
        .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 220)
    }

    @ViewBuilder
    private var detail: some View {
        switch selectedItem {
        case .home:
            HomeView()
                .environmentObject(pipelineState)
                .environmentObject(profileManager)
        case .profiles:
            ProfilesView()
                .environmentObject(profileManager)
        case .history:
            HistoryView()
                .environmentObject(memoryManager)
        case .settings:
            AppSettingsView()
                .environmentObject(settingsManager)
                .environmentObject(pipelineState)
        }
    }
}
