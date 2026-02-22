import Foundation
import SwiftData

enum JournalRepository {

    static func saveEntry(
        transcribedText: String,
        audioFilePath: String? = nil,
        aiResponse: String? = nil,
        turn: TherapyTurnEnvelope? = nil,
        moodTag: String? = nil,
        commitmentId: UUID? = nil,
        slot: RitualSlot = .morning,
        in modelContext: ModelContext
    ) {
        let entry = JournalEntryEntity(
            transcribedText: transcribedText,
            audioFilePath: audioFilePath,
            aiResponse: aiResponse,
            rawReality: turn?.rawReality,
            reframing: turn?.reframing,
            meaningAnchor: turn?.meaningAnchor,
            distortionTags: turn?.diagnosis.distortionTags ?? [],
            moodTag: moodTag,
            commitmentId: commitmentId ?? turn?.contract.id,
            slot: slot
        )
        modelContext.insert(entry)
        try? modelContext.save()
    }

    static func fetchEntries(for date: Date? = nil, in modelContext: ModelContext) -> [JournalEntryEntity] {
        var descriptor = FetchDescriptor<JournalEntryEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        if let date {
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
            descriptor.predicate = #Predicate { $0.createdAt >= start && $0.createdAt < end }
        }

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    static func fetchAllEntries(in modelContext: ModelContext) -> [JournalEntryEntity] {
        let descriptor = FetchDescriptor<JournalEntryEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    static func deleteEntry(id: UUID, in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<JournalEntryEntity>(
            predicate: #Predicate { $0.id == id }
        )

        if let entry = try? modelContext.fetch(descriptor).first {
            if let path = entry.audioFilePath {
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileURL = docs.appendingPathComponent(path)
                try? FileManager.default.removeItem(at: fileURL)
            }
            modelContext.delete(entry)
            try? modelContext.save()
        }
    }
}
