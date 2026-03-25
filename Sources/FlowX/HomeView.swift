import SwiftUI

struct HomeView: View {
    @EnvironmentObject var pipelineState: PipelineState
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var updateChecker: UpdateChecker
    @EnvironmentObject var usageTracker: UsageTracker

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Update banner
                if updateChecker.updateAvailable, let version = updateChecker.latestVersion {
                    UpdateBanner(version: version, notes: updateChecker.releaseNotes)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Error banner
                if let error = pipelineState.errorMessage {
                    ErrorBanner(message: error) {
                        pipelineState.clearError()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Paywall if limit reached
                if usageTracker.hasReachedLimit {
                    PaywallBanner()
                } else {
                    // Main status
                    StatusSection(status: pipelineState.status)
                        .padding(.top, 12)

                    // Record button
                    RecordButton(status: pipelineState.status) {
                        pipelineState.onToggleRecording?()
                    }
                }

                // Last result
                if let transcript = pipelineState.lastTranscript,
                   let result = pipelineState.lastResult {
                    LastResultCard(transcript: transcript, result: result)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.25), value: pipelineState.errorMessage)
        .animation(.easeInOut(duration: 0.25), value: pipelineState.status)
        .animation(.easeInOut(duration: 0.25), value: updateChecker.updateAvailable as Bool)
    }
}
