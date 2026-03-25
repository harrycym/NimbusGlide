import Foundation

struct WakewordParser {
    static let wakeword = "flow clone"

    enum ParseResult {
        case withCommand(content: String, command: String)
        case noCommand(content: String)
    }

    /// Parses a transcript for the "flow clone" wakeword.
    /// If found, splits into content (before) and command (after).
    /// If not found, returns the whole text as content with no command.
    static func parse(_ transcript: String) -> ParseResult {
        let lowered = transcript.lowercased()

        // Try several variations of how the wakeword might be transcribed
        let wakewordVariations = [
            "flowx",
            "flow x",
            "flow-x",
            "flow, x",
            "flow clone",
            "flowclone",
            "flow-clone",
            "flow, clone",
        ]

        for variation in wakewordVariations {
            if let range = lowered.range(of: variation) {
                let contentEnd = transcript[transcript.startIndex..<range.lowerBound]
                let commandStart = transcript[range.upperBound..<transcript.endIndex]

                let content = String(contentEnd).trimmingCharacters(in: .whitespacesAndNewlines)
                let command = String(commandStart).trimmingCharacters(in: .whitespacesAndNewlines)

                if !content.isEmpty && !command.isEmpty {
                    return .withCommand(content: content, command: command)
                } else if !content.isEmpty {
                    // Wakeword at end with no command — treat as clean-up
                    return .noCommand(content: content)
                } else if !command.isEmpty {
                    // Wakeword at start — the command is all there is, content is empty
                    return .withCommand(content: "", command: command)
                }
            }
        }

        return .noCommand(content: transcript)
    }
}
