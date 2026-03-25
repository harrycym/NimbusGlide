import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var pipelineState: PipelineState
    @State private var apiKeyInput: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Groq API Key
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Groq API Key", systemImage: "bolt.fill")
                            .font(.headline)

                        SecureField("Groq API Key (gsk_...)", text: $apiKeyInput)
                            .textFieldStyle(.roundedBorder)
                            .onAppear { apiKeyInput = settingsManager.apiKey ?? "" }
                            .onChange(of: apiKeyInput) { newValue in
                                settingsManager.apiKey = newValue.isEmpty ? nil : newValue
                            }

                        if settingsManager.hasValidAPIKey {
                            Label("Groq key configured", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(4)
                }

                // Hotkey
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Record Hotkey", systemImage: "keyboard")
                            .font(.headline)

                        Picker("Hold to record:", selection: $settingsManager.hotkey) {
                            ForEach(HotkeyChoice.allCases) { choice in
                                Text(choice.rawValue).tag(choice)
                            }
                        }
                        .pickerStyle(.radioGroup)
                    }
                    .padding(4)
                }

                // LLM Model
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("LLM Model", systemImage: "cpu")
                            .font(.headline)

                        Picker("Model:", selection: $settingsManager.llmModel) {
                            ForEach(GroqModel.allCases) { model in
                                Text(model.displayName).tag(model.rawValue)
                            }
                        }

                        Text("Whisper Large V3 is used for transcription.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(4)
                }

                // Permissions
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Permissions", systemImage: "lock.shield")
                            .font(.headline)

                        PermissionRow(
                            name: "Microphone",
                            icon: "mic.fill",
                            granted: pipelineState.isMicrophoneAuthorized
                        ) {
                            NSWorkspace.shared.open(
                                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!
                            )
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

                        Button("Refresh Permissions") {
                            pipelineState.refreshPermissions()
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(4)
                }

                // About
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("About", systemImage: "info.circle")
                            .font(.headline)

                        HStack {
                            Text("FlowX")
                                .font(.body.weight(.medium))
                            Text("v1.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("AI-powered voice dictation for macOS")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Powered by Groq — Whisper Large V3 + Llama 3")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(4)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
