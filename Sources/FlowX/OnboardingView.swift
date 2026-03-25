import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var pipelineState: PipelineState
    @EnvironmentObject var profileManager: ProfileManager

    @Binding var isComplete: Bool
    @State private var currentStep = 0

    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)

            Spacer()

            // Step content
            Group {
                switch currentStep {
                case 0: welcomeStep
                case 1: apiKeyStep
                case 2: permissionsStep
                case 3: readyStep
                default: readyStep
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.3), value: currentStep)

            Spacer()

            // Navigation buttons
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
                    Button("Get Started") {
                        isComplete = true
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(20)
        }
        .frame(width: 500, height: 400)
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("Welcome to FlowX")
                .font(.largeTitle.weight(.bold))

            Text("AI-powered voice dictation for macOS.\nSpeak naturally, get polished text.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
    }

    private var apiKeyStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)

            Text("Connect to Groq")
                .font(.title2.weight(.semibold))

            Text("FlowX uses Groq for ultra-fast transcription\n(Whisper Large V3) and text processing (Llama 3).")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                SecureField("Groq API Key (gsk_...)", text: apiKeyBinding)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 350)

                if settingsManager.hasValidAPIKey {
                    Label("Key looks good!", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Text("You can also set this later in Settings.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
    }

    private var permissionsStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)

            Text("Permissions")
                .font(.title2.weight(.semibold))

            Text("FlowX needs access to your microphone and accessibility\nto record audio and paste text.")
                .font(.callout)
                .foregroundColor(.secondary)
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
                    hint: "If FlowX is listed but not working, toggle it off and on again"
                ) {
                    PermissionsManager.checkAccessibilityAccess()
                    NSWorkspace.shared.open(
                        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                    )
                }
            }
            .frame(maxWidth: 350)

            Button("Refresh") {
                pipelineState.refreshPermissions()
            }
            .font(.caption)
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(20)
    }

    private var readyStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text("You're all set!")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 10) {
                tipRow(icon: "option", text: "Hold **Right Option** key to record")
                tipRow(icon: "text.quote", text: "Say **\"FlowX\"** + command to edit text")
                tipRow(icon: "person.2.fill", text: "Switch profiles from the menu bar")
            }
        }
        .padding(20)
    }

    private func tipRow(icon: String, text: LocalizedStringKey) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.accentColor)
            Text(text)
                .font(.callout)
        }
    }

    private var apiKeyBinding: Binding<String> {
        Binding<String>(
            get: { settingsManager.apiKey ?? "" },
            set: { settingsManager.apiKey = $0.isEmpty ? nil : $0 }
        )
    }
}
