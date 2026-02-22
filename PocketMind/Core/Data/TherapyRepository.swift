import Foundation
import SwiftData

enum TherapyRepository {
    static func currentProfile(in modelContext: ModelContext) -> TherapyProfile {
        var descriptor = FetchDescriptor<TherapyProfileEntity>()
        descriptor.fetchLimit = 1

        if let entity = try? modelContext.fetch(descriptor).first {
            return entity.profile
        }

        let profile = TherapyProfile.default
        modelContext.insert(TherapyProfileEntity(profile: profile))
        try? modelContext.save()
        return profile
    }

    static func saveProfile(_ profile: TherapyProfile, in modelContext: ModelContext) {
        var descriptor = FetchDescriptor<TherapyProfileEntity>()
        descriptor.fetchLimit = 1

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.confrontationLevel = profile.confrontationLevel
            existing.defaultModesRaw = profile.defaultModes.map(\.rawValue).joined(separator: ",")
            existing.morningStart = profile.morningWindow.start
            existing.morningEnd = profile.morningWindow.end
            existing.middayStart = profile.middayWindow.start
            existing.middayEnd = profile.middayWindow.end
            existing.eveningStart = profile.eveningWindow.start
            existing.eveningEnd = profile.eveningWindow.end
        } else {
            modelContext.insert(TherapyProfileEntity(profile: profile))
        }

        try? modelContext.save()
    }

    static func storeSession(turn: TherapyTurnEnvelope, input: String, slot: RitualSlot, phase: SessionPhase, in modelContext: ModelContext) {
        modelContext.insert(TherapySessionEntity(turn: turn, input: input, slot: slot, phase: phase))
        try? modelContext.save()
    }

    static func upsertCommitment(_ contract: CommitmentContract, slot: RitualSlot, in modelContext: ModelContext) {
        let id = contract.id
        let descriptor = FetchDescriptor<CommitmentEntity>(predicate: #Predicate { $0.id == id })

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.statement = contract.statement
            existing.nextAction = contract.nextAction
            existing.durationMinutes = contract.durationMinutes
            existing.dueAt = contract.dueAt
            existing.accountabilityPrompt = contract.accountabilityPrompt
            existing.statusRaw = contract.status.rawValue
            existing.slotRaw = slot.rawValue
        } else {
            modelContext.insert(CommitmentEntity(contract: contract, slot: slot))
        }

        try? modelContext.save()
    }

    static func fetchCommitments(for date: Date? = nil, in modelContext: ModelContext) -> [CommitmentEntity] {
        var descriptor = FetchDescriptor<CommitmentEntity>(sortBy: [SortDescriptor(\.dueAt)])

        if let date {
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
            descriptor.predicate = #Predicate { $0.dueAt >= start && $0.dueAt < end }
        }

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    static func updateCommitmentStatus(id: UUID, status: CommitmentStatus, in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<CommitmentEntity>(predicate: #Predicate { $0.id == id })

        guard let existing = try? modelContext.fetch(descriptor).first else {
            return
        }

        existing.statusRaw = status.rawValue
        try? modelContext.save()
    }

    static func saveReview(
        date: Date,
        wins: [String],
        frictions: [String],
        lesson: String,
        adjustment: String,
        consistencyScore: Int,
        in modelContext: ModelContext
    ) {
        let dayStart = Calendar.current.startOfDay(for: date)
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? date

        let descriptor = FetchDescriptor<DailyReviewEntity>(
            predicate: #Predicate { $0.date >= dayStart && $0.date < nextDay }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.winsRaw = wins.joined(separator: "|")
            existing.frictionsRaw = frictions.joined(separator: "|")
            existing.lesson = lesson
            existing.adjustmentForTomorrow = adjustment
            existing.consistencyScore = consistencyScore
        } else {
            modelContext.insert(
                DailyReviewEntity(
                    date: date,
                    wins: wins,
                    frictions: frictions,
                    lesson: lesson,
                    adjustmentForTomorrow: adjustment,
                    consistencyScore: consistencyScore
                )
            )
        }

        try? modelContext.save()
    }

    static func logMetric(name: String, value: Double, context: String, in modelContext: ModelContext) {
        modelContext.insert(MetricEventEntity(name: name, value: value, context: context))
        try? modelContext.save()
    }

    static func enqueueIntegration(kind: String, payload: String, in modelContext: ModelContext) {
        modelContext.insert(IntegrationQueueItemEntity(kind: kind, payload: payload))
        try? modelContext.save()
    }

    static func queuedIntegrations(in modelContext: ModelContext) -> [IntegrationQueueItemEntity] {
        let descriptor = FetchDescriptor<IntegrationQueueItemEntity>(sortBy: [SortDescriptor(\.createdAt)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    static func removeQueueItem(_ item: IntegrationQueueItemEntity, in modelContext: ModelContext) {
        modelContext.delete(item)
        try? modelContext.save()
    }

    static func registerRetry(for item: IntegrationQueueItemEntity, error: String, in modelContext: ModelContext) {
        item.retries += 1
        item.lastError = error
        try? modelContext.save()
    }
}
