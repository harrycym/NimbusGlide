import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var memoryManager: MemoryManager
    @State private var searchText = ""
    @State private var selectedEntryId: UUID?

    private var filteredEntries: [MemoryEntry] {
        if searchText.isEmpty { return memoryManager.entries }
        return memoryManager.entries.filter {
            $0.rawTranscript.localizedCaseInsensitiveContains(searchText) ||
            $0.polishedText.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("\(memoryManager.entries.count) dictations")
                    .font(NimbusFonts.caption)
                    .foregroundColor(NimbusColors.muted)
                Spacer()
                if !memoryManager.entries.isEmpty {
                    Button("Clear All") {
                        memoryManager.clearAll()
                    }
                    .font(NimbusFonts.caption)
                    .foregroundColor(NimbusColors.error)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()

            if memoryManager.entries.isEmpty {
                emptyState
            } else {
                List(selection: $selectedEntryId) {
                    ForEach(filteredEntries) { entry in
                        HistoryRow(entry: entry)
                            .tag(entry.id)
                    }
                    .onDelete { offsets in
                        let idsToDelete = offsets.map { filteredEntries[$0].id }
                        for id in idsToDelete {
                            memoryManager.deleteEntry(id: id)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .searchable(text: $searchText, prompt: "Search dictations")
        .background(NimbusColors.warmBg)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: NimbusLayout.emptyStateIconSize, weight: .light))
                .foregroundStyle(NimbusGradients.primary)
            Text("No dictation history")
                .font(NimbusFonts.sectionHeader)
                .foregroundColor(NimbusColors.muted)
            Text("Your transcriptions will appear here\nafter your first dictation.")
                .font(NimbusFonts.caption)
                .foregroundColor(NimbusColors.muted)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - History Row

private struct HistoryRow: View {
    let entry: MemoryEntry
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.timestamp, style: .relative)
                    .font(NimbusFonts.small)
                    .foregroundColor(NimbusColors.muted)
                Text("ago")
                    .font(NimbusFonts.small)
                    .foregroundColor(NimbusColors.muted)
                Spacer()
                Button(action: copyText) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(NimbusFonts.caption)
                        .foregroundColor(copied ? NimbusColors.ready : NimbusColors.muted)
                }
                .buttonStyle(.plain)
                .help("Copy result")
            }

            Text(entry.rawTranscript)
                .font(NimbusFonts.caption)
                .foregroundColor(NimbusColors.muted)
                .lineLimit(2)

            Text(entry.polishedText)
                .font(NimbusFonts.body)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }

    private func copyText() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(entry.polishedText, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
    }
}
