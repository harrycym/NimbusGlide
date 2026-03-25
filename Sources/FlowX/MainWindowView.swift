import SwiftUI

extension Notification.Name {
    static let flowxNavigateToSettings = Notification.Name("flowxNavigateToSettings")
    static let flowxNavigateToHistory = Notification.Name("flowxNavigateToHistory")
}

enum SidebarItem: String, CaseIterable, Identifiable {
    case home = "Home"
    case profiles = "Profiles"
    case history = "History"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "waveform"
        case .profiles: return "person.2"
        case .history: return "clock"
        case .settings: return "gear"
        }
    }
}

struct MainWindowView: View {
    @EnvironmentObject var pipelineState: PipelineState
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var memoryManager: MemoryManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var usageTracker: UsageTracker
    @EnvironmentObject var updateChecker: UpdateChecker

    @State private var selectedItem: SidebarItem = .home
    @AppStorage("flowx_onboarding_complete") private var hasCompletedOnboarding = false

    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView(isComplete: $hasCompletedOnboarding)
                .environmentObject(pipelineState)
        } else {
            NavigationSplitView {
                sidebar
            } detail: {
                detail
            }
            .frame(minWidth: 650, minHeight: 450)
            .onReceive(NotificationCenter.default.publisher(for: .flowxNavigateToSettings)) { _ in
                selectedItem = .settings
            }
            .onReceive(NotificationCenter.default.publisher(for: .flowxNavigateToHistory)) { _ in
                selectedItem = .history
            }
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .listStyle(.sidebar)

            Divider()

            UsageMeter()
                .environmentObject(usageTracker)

            StatusPill(status: pipelineState.status)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
        }
        .navigationSplitViewColumnWidth(min: 160, ideal: 190, max: 220)
    }

    @ViewBuilder
    private var detail: some View {
        switch selectedItem {
        case .home:
            HomeView()
                .environmentObject(pipelineState)
                .environmentObject(profileManager)
                .environmentObject(usageTracker)
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
                .environmentObject(usageTracker)
                .environmentObject(updateChecker)
        }
    }
}
