import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var pipelineState: PipelineState
    @Binding var isComplete: Bool
    @State private var currentStep = 0

    private let totalSteps = 2

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? NimbusColors.indigo : NimbusColors.muted.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 24)

            Spacer()

            Group {
                switch currentStep {
                case 0: welcomeStep
                case 1: permissionsStep
                default: permissionsStep
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.3), value: currentStep)

            Spacer()

            HStack {
                if currentStep > 0 {
                    Button("Back") { currentStep -= 1 }
                        .keyboardShortcut(.cancelAction)
                }
                Spacer()
                if currentStep < totalSteps - 1 {
                    Button("Continue") { currentStep += 1 }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                } else {
                    Button("Start Speaking") {
                        isComplete = true
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(24)
        }
        .frame(width: NimbusLayout.sheetWidth, height: 380)
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(NimbusGradients.primary)

            Text("Welcome to NimbusGlide")
                .font(.largeTitle.weight(.bold))

            Text("Speak naturally. Get polished text.\nPasted right where you need it.")
                .font(NimbusFonts.body)
                .foregroundColor(NimbusColors.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            VStack(alignment: .leading, spacing: 8) {
                featureRow(icon: "mic.fill", text: "Hold a key, speak, release")
                featureRow(icon: "sparkles", text: "AI cleans up your words instantly")
                featureRow(icon: "doc.on.clipboard", text: "Auto-pastes into any app")
            }
            .padding(.top, 4)
        }
        .padding(24)
    }

    private var permissionsStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(NimbusGradients.primary)

            Text("Quick Setup")
                .font(.title2.weight(.semibold))

            Text("NimbusGlide needs two permissions to work.\nThis only takes a moment.")
                .font(NimbusFonts.body)
                .foregroundColor(NimbusColors.muted)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                PermissionRow(
                    name: "Microphone",
                    icon: "mic.fill",
                    granted: pipelineState.isMicrophoneAuthorized
                ) {
                    PermissionsManager.requestMicrophoneAccess { granted in
                        DispatchQueue.main.async {
                            pipelineState.isMicrophoneAuthorized = granted
                        }
                    }
                }

                PermissionRow(
                    name: "Accessibility",
                    icon: "accessibility",
                    granted: pipelineState.isAccessibilityAuthorized,
                    hint: "Needed to paste text into your apps"
                ) {
                    PermissionsManager.checkAccessibilityAccess()
                    NSWorkspace.shared.open(
                        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                    )
                }
            }
            .frame(maxWidth: 320)
        }
        .padding(24)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(NimbusGradients.primary)
            Text(text)
                .font(NimbusFonts.body)
                .foregroundColor(NimbusColors.muted)
        }
    }
}
