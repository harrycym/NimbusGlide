import Foundation
import SwiftUI

struct MemoryEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var rawTranscript: String
    var polishedText: String
    var timestamp: Date = Date()
}

class MemoryManager: ObservableObject {
    private static let storageKey = "flowx_memory_entries"
    private static let maxEntries = 50

    @Published var entries: [MemoryEntry] {
        didSet { save() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([MemoryEntry].self, from: data) {
            self.entries = decoded
        } else {
            self.entries = []
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    func addEntry(rawTranscript: String, polishedText: String) {
        let entry = MemoryEntry(rawTranscript: rawTranscript, polishedText: polishedText)
        entries.insert(entry, at: 0)

        // Trim to max entries
        if entries.count > Self.maxEntries {
            entries = Array(entries.prefix(Self.maxEntries))
        }
    }

    func deleteEntry(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
    }

    func deleteEntry(id: UUID) {
        entries.removeAll { $0.id == id }
    }

    func clearAll() {
        entries.removeAll()
    }

    /// Returns the most recent entries for few-shot learning injection.
    func recentExamples(limit: Int = 5) -> [MemoryEntry] {
        return Array(entries.prefix(limit))
    }
}
