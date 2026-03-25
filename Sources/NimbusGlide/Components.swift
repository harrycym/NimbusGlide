import SwiftUI
import AppKit

// MARK: - Status Pill (sidebar footer)

struct StatusPill: View {
    let status: PipelineStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusLabel)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(statusColor.opacity(0.08))
        .cornerRadius(12)
    }

    private var statusLabel: String {
        switch status {
        case .idle: return "Ready"
        case .recording: return "Listening"
        case .processing: return "Thinking"
        case .error: return "Error"
        }
    }

    private var statusColor: Color {
        switch status {
        case .idle: return .green
        case .recording: return .red
        case .processing: return .orange
        case .error: return .red
        }
    }
}

// MARK: - Status Section (home dashboard)

struct StatusSection: View {
    let status: PipelineStatus
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.06))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 100, height: 100)
                    .scaleEffect(status == .recording && isAnimating ? 1.3 : 1.0)
                    .animation(
                        status == .recording
                            ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                            : .default,
                        value: isAnimating
                    )

                if status == .processing {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(.circular)
                } else {
                    Image(systemName: statusIcon)
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(statusColor)
                }
            }

            Text(statusLabel)
                .font(.title3.weight(.medium))
                .foregroundColor(statusColor)

            Text(statusHint)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onAppear { isAnimating = true }
        .onChange(of: status) { _ in isAnimating = true }
    }

    private var statusLabel: String {
        switch status {
        case .idle: return "Ready"
        case .recording: return "Listening..."
        case .processing: return "Polishing your words..."
        case .error: return "Something went wrong"
        }
    }

    private var statusHint: String {
        switch status {
        case .idle: return "Hold your hotkey or tap the button to speak"
        case .recording: return "Release when you're done"
        case .processing: return "This usually takes a second"
        case .error: return "Check the error above for details"
        }
    }

    private var statusColor: Color {
        switch status {
        case .idle: return .green
        case .recording: return .red
        case .processing: return .orange
        case .error: return .red
        }
    }

    private var statusIcon: String {
        switch status {
        case .idle: return "waveform"
        case .recording: return "mic.fill"
        case .processing: return "sparkles"
        case .error: return "exclamationmark.circle"
        }
    }
}

// MARK: - Record Button

struct RecordButton: View {
    let status: PipelineStatus
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: buttonIcon)
                    .font(.body.weight(.medium))
                Text(buttonLabel)
                    .font(.body.weight(.medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(buttonColor)
            .cornerRadius(25)
            .scaleEffect(isHovering ? 1.04 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in isHovering = hovering }
        .disabled(status == .processing)
    }

    private var buttonIcon: String {
        switch status {
        case .recording: return "stop.fill"
        case .processing: return "hourglass"
        default: return "mic.fill"
        }
    }

    private var buttonLabel: String {
        switch status {
        case .recording: return "Stop"
        case .processing: return "Working..."
        default: return "Speak"
        }
    }

    private var buttonColor: Color {
        switch status {
        case .recording: return .red
        case .processing: return .gray
        default: return .accentColor
        }
    }
}

// MARK: - Last Result Card

struct LastResultCard: View {
    let transcript: String
    let result: String
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Last dictation")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: copyResult) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(copied ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .help("Copy to clipboard")
            }

            Text(result)
                .font(.body)
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
        }
    }

    private func copyResult() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
    }
}

// MARK: - Usage Meter

struct UsageMeter: View {
    @EnvironmentObject var usageTracker: UsageTracker

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(usageTracker.totalWordsUsed.formatted()) words used")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if !usageTracker.isPaid {
                    Text("\(usageTracker.wordsRemaining.formatted()) left")
                        .font(.caption)
                        .foregroundColor(usageTracker.usageRatio > 0.8 ? .orange : .secondary)
                }
            }

            if !usageTracker.isPaid {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(usageTracker.usageRatio > 0.8 ? Color.orange : Color.accentColor)
                            .frame(width: geo.size.width * usageTracker.usageRatio, height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Paywall Banner

struct PaywallBanner: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 28))
                .foregroundColor(.orange)

            Text("Free trial ended")
                .font(.headline)

            Text("You've used your free words.\nUpgrade to keep speaking.")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Upgrade") {
                // TODO: Link to payment portal
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Update Banner

struct UpdateBanner: View {
    let version: String
    let notes: String?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("NimbusGlide \(version) available")
                    .font(.callout.weight(.medium))
                    .foregroundColor(.white)
                if let notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                }
            }
            Spacer()
            Button("Update") {
                NSWorkspace.shared.open(URL(string: "https://github.com/harrycym/NimbusGlide")!)
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .controlSize(.small)
        }
        .padding(12)
        .background(Color.accentColor)
        .cornerRadius(10)
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            Text(message)
                .font(.callout)
                .foregroundColor(.white)
                .lineLimit(2)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.red.opacity(0.9))
        .cornerRadius(10)
    }
}

// MARK: - Permission Row

struct PermissionRow: View {
    let name: String
    let icon: String
    let granted: Bool
    var hint: String? = nil
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                    .foregroundColor(granted ? .green : .orange)
                Text(name)
                Spacer()
                if granted {
                    Label("Granted", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Button("Grant Access", action: action)
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
            if !granted, let hint {
                Text(hint)
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .padding(.leading, 32)
            }
        }
    }
}
