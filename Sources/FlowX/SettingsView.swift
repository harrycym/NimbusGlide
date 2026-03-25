import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var memoryManager: MemoryManager

    var body: some View {
        GeneralTab()
            .environmentObject(settingsManager)
            .frame(width: 450, height: 300)
    }
}

// MARK: - General Tab

private struct GeneralTab: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var apiKeyInput: String = ""

    var body: some View {
        Form {
            Section {
                SecureField("Groq API Key (gsk_...)", text: $apiKeyInput)
                    .onAppear { apiKeyInput = settingsManager.apiKey ?? "" }
                    .onChange(of: apiKeyInput) { newValue in
                        settingsManager.apiKey = newValue.isEmpty ? nil : newValue
                    }

                if settingsManager.hasValidAPIKey {
                    Text("Groq key set")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            } header: {
                Text("Groq API Key")
            }

            Section {
                Picker("Model", selection: $settingsManager.llmModel) {
                    ForEach(GroqModel.allCases) { model in
                        Text(model.displayName).tag(model.rawValue)
                    }
                }
            } header: {
                Text("LLM Model")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Profiles Tab

private struct ProfilesTab: View {
    @EnvironmentObject var profileManager: ProfileManager
    @State private var selectedProfileId: UUID?
    @State private var editingProfile: Profile?
    @State private var showingAddSheet = false

    var body: some View {
        HSplitView {
            // Profile list
            List(selection: $selectedProfileId) {
                ForEach(profileManager.profiles) { profile in
                    HStack {
                        Text(profile.name)
                        if profile.id == profileManager.activeProfileId {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                                .font(.caption)
                        }
                    }
                    .tag(profile.id)
                }
                .onDelete { offsets in
                    profileManager.deleteProfile(at: offsets)
                }
            }
            .frame(minWidth: 150)
            .toolbar {
                ToolbarItemGroup {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }

            // Detail view
            if let id = selectedProfileId,
               let profile = profileManager.profiles.first(where: { $0.id == id }) {
                ProfileDetailView(profile: profile, profileManager: profileManager)
            } else {
                Text("Select a profile")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddProfileSheet(profileManager: profileManager, isPresented: $showingAddSheet)
        }
    }
}

private struct ProfileDetailView: View {
    @State var profile: Profile
    let profileManager: ProfileManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Name", text: $profile.name)
                .textFieldStyle(.roundedBorder)

            Text("Instructions")
                .font(.headline)

            TextEditor(text: $profile.instructions)
                .font(.body)
                .border(Color.secondary.opacity(0.3))

            HStack {
                Button("Set as Active") {
                    profileManager.activeProfileId = profile.id
                }
                .disabled(profile.id == profileManager.activeProfileId)

                Spacer()

                Button("Save") {
                    profileManager.updateProfile(profile)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

private struct AddProfileSheet: View {
    let profileManager: ProfileManager
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var instructions = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("New Profile")
                .font(.headline)

            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)

            TextEditor(text: $instructions)
                .frame(height: 100)
                .border(Color.secondary.opacity(0.3))

            HStack {
                Button("Cancel") { isPresented = false }
                Spacer()
                Button("Add") {
                    let profile = Profile(name: name, instructions: instructions)
                    profileManager.addProfile(profile)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 350, height: 250)
    }
}

// MARK: - Memory Tab

private struct MemoryTab: View {
    @EnvironmentObject var memoryManager: MemoryManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Few-Shot Learning Memory")
                    .font(.headline)
                Spacer()
                Text("\(memoryManager.entries.count) entries")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Button("Clear All") {
                    memoryManager.clearAll()
                }
                .disabled(memoryManager.entries.isEmpty)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            if memoryManager.entries.isEmpty {
                Spacer()
                Text("No memory entries yet.\nEntries are saved automatically after each dictation.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                List {
                    ForEach(memoryManager.entries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.rawTranscript)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            Text(entry.polishedText)
                                .font(.body)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete { offsets in
                        memoryManager.deleteEntry(at: offsets)
                    }
                }
            }
        }
    }
}
