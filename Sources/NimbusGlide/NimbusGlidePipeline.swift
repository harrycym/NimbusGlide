import Foundation
import AppKit

class NimbusGlidePipeline {
    private let audioRecorder: AudioRecorder
    private let aiService: AIService
    private let appTracker: AppTracker
    private let keystrokeSimulator: KeystrokeSimulator
    private let profileManager: ProfileManager
    private let memoryManager: MemoryManager

    private var isProcessing = false
    weak var menuBarManager: MenuBarManager?
    var pipelineState: PipelineState?
    var settingsManager: SettingsManager?

    /// Tracks the last non-NimbusGlide frontmost app (for manual record button)
    private var lastExternalApp: String = "Unknown"

    init(
        audioRecorder: AudioRecorder,
        aiService: AIService,
        appTracker: AppTracker,
        keystrokeSimulator: KeystrokeSimulator,
        profileManager: ProfileManager,
        memoryManager: MemoryManager
    ) {
        self.audioRecorder = audioRecorder
        self.aiService = aiService
        self.appTracker = appTracker
        self.keystrokeSimulator = keystrokeSimulator
        self.profileManager = profileManager
        self.memoryManager = memoryManager
    }

    func toggleRecording() {
        if audioRecorder.isRecording {
            stopRecordingAndProcess()
        } else {
            startRecording()
        }
    }

    func startRecording() {
        guard !isProcessing else {
            print("[NimbusGlide] Already processing, ignoring record request")
            return
        }

        // Capture frontmost app before NimbusGlide potentially takes focus
        let currentApp = appTracker.frontmostAppName()
        if currentApp != "NimbusGlide" {
            lastExternalApp = currentApp
        }

        audioRecorder.startRecording()
        menuBarManager?.setRecordingIndicator(true)
        menuBarManager?.updateStatus("Recording…")

        DispatchQueue.main.async {
            self.pipelineState?.status = .recording
            CursorManager.showMicCursor()
        }
    }

    func stopRecordingAndProcess() {
        guard let recordingURL = audioRecorder.stopRecording() else {
            print("[NimbusGlide] No recording to process")
            menuBarManager?.setRecordingIndicator(false)
            menuBarManager?.updateStatus("Ready")
            DispatchQueue.main.async {
                self.pipelineState?.status = .idle
            }
            return
        }

        menuBarManager?.setRecordingIndicator(false)
        menuBarManager?.updateStatus("Processing…")
        isProcessing = true

        DispatchQueue.main.async {
            CursorManager.restoreCursor()
            self.pipelineState?.status = .processing
        }

        // Use the last external app if NimbusGlide is frontmost (manual record button case)
        let currentApp = appTracker.frontmostAppName()
        let activeApp = (currentApp == "NimbusGlide") ? lastExternalApp : currentApp
        let profileInstructions = profileManager.activeProfile?.instructions
        let memoryExamples = memoryManager.recentExamples()

        Task {
            do {
                let transcript = try await aiService.transcribeAudio(fileURL: recordingURL)
                print("[NimbusGlide] Transcript: \(transcript)")

                guard !transcript.isEmpty else {
                    print("[NimbusGlide] Empty transcript, skipping")
                    await finish(status: .idle)
                    return
                }

                let result = try await aiService.processWithLLM(
                    transcript: transcript,
                    activeApp: activeApp,
                    profileInstructions: profileInstructions,
                    memoryExamples: memoryExamples
                )
                print("[NimbusGlide] Result: \(result)")

                guard !result.isEmpty else {
                    print("[NimbusGlide] Empty LLM result, skipping")
                    await finish(status: .idle)
                    return
                }

                // Save to memory for few-shot learning
                await MainActor.run {
                    memoryManager.addEntry(rawTranscript: transcript, polishedText: result)
                    pipelineState?.recordSuccess(transcript: transcript, result: result)
                }

                // Auto-copy to clipboard if enabled
                if self.settingsManager?.autoCopyToClipboard == true {
                    await MainActor.run {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(result, forType: .string)
                    }
                }

                // Paste into frontmost app
                await MainActor.run {
                    keystrokeSimulator.pasteText(result)
                }

                await finish(status: .idle)

            } catch {
                print("[NimbusGlide] Pipeline error: \(error.localizedDescription)")
                await MainActor.run {
                    pipelineState?.status = .error
                    pipelineState?.errorMessage = error.localizedDescription
                }
                await finish(status: .error)
            }

            audioRecorder.cleanup()
        }
    }

    @MainActor
    private func finish(status: PipelineStatus) {
        isProcessing = false
        menuBarManager?.updateStatus(status.rawValue)
        // Only set idle if we're finishing successfully — error state is set in catch
        if status == .idle {
            pipelineState?.status = .idle
        }
    }
}
