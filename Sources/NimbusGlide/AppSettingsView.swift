import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var pipelineState: PipelineState
    @EnvironmentObject var usageTracker: UsageTracker
    @EnvironmentObject var updateChecker: UpdateChecker
    @State private var showLanguageUpgradeAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hotkey
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Hotkey", systemImage: "keyboard")
                            .font(.system(size: 15, weight: .semibold))

                        Text("Hold this key to dictate, release to process.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        Picker("", selection: $settingsManager.hotkey) {
                            ForEach(HotkeyChoice.allCases) { choice in
                                Text(choice.rawValue).tag(choice)
                            }
                        }
                        .pickerStyle(.radioGroup)
                        .labelsHidden()

                        if settingsManager.hotkey == .custom {
                            HotkeyRecorderRow()
                                .environmentObject(settingsManager)
                        }
                    }
                    .padding(4)
                }

                // Permissions
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Permissions", systemImage: "lock.shield")
                            .font(.system(size: 15, weight: .semibold))

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
                            hint: "If listed but not working, toggle it off and on"
                        ) {
                            PermissionsManager.checkAccessibilityAccess()
                            NSWorkspace.shared.open(
                                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                            )
                        }
                    }
                    .padding(4)
                }

                // Appearance
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Appearance", systemImage: "paintbrush")
                            .font(.system(size: 15, weight: .semibold))

                        Toggle(isOn: $settingsManager.showStatusIndicator) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Floating status indicator")
                                    .font(.system(size: 14))
                                Text("Shows a small pill at the bottom center when recording or processing")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(4)
                }

                // Language
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Language", systemImage: "globe")
                            .font(.system(size: 15, weight: .semibold))

                        if usageTracker.isPro {
                            Text("Select which languages the AI may respond in. Multi-language support auto-detects and responds in the matching language.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Choose your dictation language. You can switch anytime — free tier supports one language at a time. Upgrade to Pro for multi-language.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), alignment: .leading)], spacing: 6) {
                            ForEach(SettingsManager.supportedLanguages, id: \.self) { language in
                                Toggle(language, isOn: Binding(
                                    get: { settingsManager.selectedLanguages.contains(language) },
                                    set: { isOn in
                                        if isOn {
                                            if usageTracker.isPro {
                                                // Pro: add language
                                                settingsManager.selectedLanguages.append(language)
                                            } else {
                                                // Free: swap to this language (only 1 allowed)
                                                settingsManager.selectedLanguages = [language]
                                            }
                                        } else {
                                            if usageTracker.isPro {
                                                settingsManager.selectedLanguages.removeAll { $0 == language }
                                            }
                                            // Free: don't allow deselecting the only language
                                        }
                                    }
                                ))
                                .font(.system(size: 14))
                            }
                        }
                    }
                    .padding(4)
                }
                .alert("Multi-language is a Pro feature", isPresented: $showLanguageUpgradeAlert) {
                    Button("Upgrade to Pro") {
                        // Navigate to account/upgrade
                        NotificationCenter.default.post(name: .nimbusglideNavigateToAccount, object: nil)
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Free tier supports one language at a time. Upgrade to Pro to dictate in multiple languages with auto-detection.")
                }

                // Usage
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Usage", systemImage: "chart.bar")
                            .font(.system(size: 15, weight: .semibold))

                        HStack {
                            Text("\(usageTracker.totalWordsUsed.formatted()) words used")
                                .font(.system(size: 14))
                            Spacer()
                            if usageTracker.isPro {
                                Label("Pro", systemImage: "checkmark.seal.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.accentColor)
                            } else if let limit = usageTracker.wordLimit {
                                Text("\(max(0, limit - usageTracker.totalWordsUsed).formatted()) remaining")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }

                        if !usageTracker.isPro {
                            ProgressView(value: usageTracker.usageRatio)
                                .tint(usageTracker.usageRatio > 0.8 ? .orange : .accentColor)
                        }
                    }
                    .padding(4)
                }

                // About & Updates
                GroupBox {
                    // About
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("NimbusGlide")
                                .font(.system(size: 14, weight: .medium))
                            Text("Version \(UpdateChecker.currentVersion)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Check for Updates") {
                            updateChecker.checkForUpdates()
                        }
                        .disabled(!updateChecker.canCheckForUpdates)
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(4)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NimbusColors.warmBg)
    }
}
