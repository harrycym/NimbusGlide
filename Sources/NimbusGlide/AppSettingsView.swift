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
                VStack(alignment: .leading, spacing: 12) {
                    Label("Hotkey", systemImage: "keyboard")
                        .font(NimbusFonts.sectionHeader)

                    Text("Hold this key to dictate, release to process.")
                        .font(NimbusFonts.caption)
                        .foregroundColor(NimbusColors.muted)

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
                .padding(16)
                .nimbusCard()

                // Permissions
                VStack(alignment: .leading, spacing: 12) {
                    Label("Permissions", systemImage: "lock.shield")
                        .font(NimbusFonts.sectionHeader)

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
                .padding(16)
                .nimbusCard()

                // Appearance
                VStack(alignment: .leading, spacing: 12) {
                    Label("Appearance", systemImage: "paintbrush")
                        .font(NimbusFonts.sectionHeader)

                    Toggle(isOn: $settingsManager.showStatusIndicator) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Floating status indicator")
                                .font(NimbusFonts.body)
                            Text("Shows a small pill at the bottom center when recording or processing")
                                .font(NimbusFonts.caption)
                                .foregroundColor(NimbusColors.muted)
                        }
                    }
                }
                .padding(16)
                .nimbusCard()

                // Language
                VStack(alignment: .leading, spacing: 12) {
                    Label("Language", systemImage: "globe")
                        .font(NimbusFonts.sectionHeader)

                    if usageTracker.isPro {
                        Text("Select which languages the AI may respond in. Multi-language support auto-detects and responds in the matching language.")
                            .font(NimbusFonts.caption)
                            .foregroundColor(NimbusColors.muted)
                    } else {
                        Text("Choose your dictation language. You can switch anytime — free tier supports one language at a time. Upgrade to Pro for multi-language.")
                            .font(NimbusFonts.caption)
                            .foregroundColor(NimbusColors.muted)
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
                            .font(NimbusFonts.body)
                        }
                    }
                }
                .padding(16)
                .nimbusCard()
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
                VStack(alignment: .leading, spacing: 8) {
                    Label("Usage", systemImage: "chart.bar")
                        .font(NimbusFonts.sectionHeader)

                    HStack {
                        Text("\(usageTracker.totalWordsUsed.formatted()) words used")
                            .font(NimbusFonts.body)
                        Spacer()
                        if usageTracker.isPro {
                            Label("Pro", systemImage: "checkmark.seal.fill")
                                .font(NimbusFonts.caption)
                                .foregroundColor(NimbusColors.indigo)
                        } else if let limit = usageTracker.wordLimit {
                            Text("\(max(0, limit - usageTracker.totalWordsUsed).formatted()) remaining")
                                .font(NimbusFonts.caption)
                                .foregroundColor(NimbusColors.muted)
                        }
                    }

                    if !usageTracker.isPro {
                        ProgressView(value: usageTracker.usageRatio)
                            .tint(usageTracker.usageRatio > 0.8 ? NimbusColors.processing : NimbusColors.indigo)
                    }
                }
                .padding(16)
                .nimbusCard()

                // About & Updates
                VStack {
                    // About
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("NimbusGlide")
                                .font(NimbusFonts.bodyMedium)
                            Text("Version \(UpdateChecker.currentVersion)")
                                .font(NimbusFonts.caption)
                                .foregroundColor(NimbusColors.muted)
                        }
                        Spacer()
                        Button("Check for Updates") {
                            updateChecker.checkForUpdates()
                        }
                        .disabled(!updateChecker.canCheckForUpdates)
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(16)
                .nimbusCard()
            }
            .padding(NimbusLayout.contentPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NimbusColors.warmBg)
    }
}
