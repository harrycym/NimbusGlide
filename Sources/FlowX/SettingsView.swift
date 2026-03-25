import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var memoryManager: MemoryManager
    @EnvironmentObject var updateChecker: UpdateChecker

    var body: some View {
        GeneralTab()
            .environmentObject(settingsManager)
            .environmentObject(updateChecker)
            .frame(width: 460, height: 380)
    }
}

struct GeneralTab: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var updateChecker: UpdateChecker
    @State private var isRecordingKey = false
    @State private var keyMonitor: Any?

    var body: some View {
        Form {
            Section {
                Picker("Push-to-Dictate Key", selection: $settingsManager.hotkey) {
                    ForEach(HotkeyChoice.allCases) { choice in
                        Text(choice.rawValue).tag(choice)
                    }
                }
                if settingsManager.hotkey == .custom {
                    HStack {
                        Text("Current Key:")
                        Spacer()
                        Text(settingsManager.customKeyLabel)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(6)
                            .font(.system(.body, design: .monospaced))
                        Button(isRecordingKey ? "Press any key…" : "Record Key") {
                            startRecording()
                        }
                        .buttonStyle(.bordered)
                        .tint(isRecordingKey ? .red : .accentColor)
                    }
                }
            } header: {
                Text("Hotkey")
            }

            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Version: \(UpdateChecker.currentVersion)")
                        if let updateNotes = updateChecker.releaseNotes, updateChecker.updateAvailable {
                            Text(updateNotes).font(.caption).foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Button(updateChecker.updateAvailable ? "Install Update" : "Check for Updates") {
                        if updateChecker.updateAvailable {
                            installUpdate()
                        } else {
                            updateChecker.checkForUpdate()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(updateChecker.updateAvailable ? .blue : .secondary)
                }
            } header: {
                Text("Updates")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func startRecording() {
        isRecordingKey = true
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let label = event.charactersIgnoringModifiers?.uppercased() ?? "Key \(event.keyCode)"
            self.settingsManager.customKeyCode  = event.keyCode
            self.settingsManager.customKeyLabel = label
            self.stopRecording()
            return nil // Consume the event
        }
    }

    private func stopRecording() {
        isRecordingKey = false
        if let monitor = keyMonitor { NSEvent.removeMonitor(monitor); keyMonitor = nil }
    }

    private func installUpdate() {
        let script = """
        tell application "Terminal"
            activate
            do script "cd '/Users/harry/Documents/apps/Cool App (test)/FlowX' && git pull origin main && ./update_app.sh"
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            var errorInfo: NSDictionary?
            appleScript.executeAndReturnError(&errorInfo)
        }
        NSApp.terminate(nil)
    }
}
