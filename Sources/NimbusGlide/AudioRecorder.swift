import AVFoundation
import AppKit

class AudioRecorder: NSObject {
    private var audioRecorder: AVAudioRecorder?
    private(set) var isRecording = false
    private(set) var lastRecordingURL: URL?

    private var recordingDirectory: URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("NimbusGlide", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    func startRecording() {
        guard !isRecording else { return }

        let url = recordingDirectory.appendingPathComponent("recording_\(Date().timeIntervalSince1970).wav")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
            lastRecordingURL = url
            playStartSound()
            print("[NimbusGlide] Recording started: \(url.lastPathComponent)")
        } catch {
            print("[NimbusGlide] Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() -> URL? {
        guard isRecording, let recorder = audioRecorder else { return nil }

        recorder.stop()
        isRecording = false
        playStopSound()
        print("[NimbusGlide] Recording stopped: \(lastRecordingURL?.lastPathComponent ?? "unknown")")
        return lastRecordingURL
    }

    func cleanup() {
        if let url = lastRecordingURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func playStartSound() {
        NSSound(named: .init("Tink"))?.play()
    }

    private func playStopSound() {
        NSSound(named: .init("Pop"))?.play()
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("[NimbusGlide] Recording finished unsuccessfully")
        }
    }
}
