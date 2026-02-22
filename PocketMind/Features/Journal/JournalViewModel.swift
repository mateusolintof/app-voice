import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class JournalViewModel {
    var entries: [JournalEntryEntity] = []
    var searchText: String = ""

    func loadEntries(modelContext: ModelContext) {
        entries = JournalRepository.fetchAllEntries(in: modelContext)
    }

    var filteredEntries: [JournalEntryEntity] {
        guard !searchText.isEmpty else { return entries }
        let query = searchText.lowercased()
        return entries.filter {
            $0.transcribedText.lowercased().contains(query) ||
            ($0.aiResponse?.lowercased().contains(query) ?? false) ||
            ($0.moodTag?.lowercased().contains(query) ?? false)
        }
    }

    var groupedEntries: [(String, [JournalEntryEntity])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) { entry -> String in
            if calendar.isDateInToday(entry.createdAt) {
                return "Hoje"
            } else if calendar.isDateInYesterday(entry.createdAt) {
                return "Ontem"
            } else {
                return entry.createdAt.formatted(.dateTime.day().month().year())
            }
        }

        let order: [String: Int] = ["Hoje": 0, "Ontem": 1]

        return grouped.sorted { a, b in
            let aOrder = order[a.key] ?? 2
            let bOrder = order[b.key] ?? 2
            if aOrder != bOrder { return aOrder < bOrder }
            let aDate = a.value.first?.createdAt ?? .distantPast
            let bDate = b.value.first?.createdAt ?? .distantPast
            return aDate > bDate
        }
    }

    func deleteEntry(id: UUID, modelContext: ModelContext) {
        JournalRepository.deleteEntry(id: id, in: modelContext)
        loadEntries(modelContext: modelContext)
    }
}
