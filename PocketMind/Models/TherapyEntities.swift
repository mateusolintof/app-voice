import Foundation
import SwiftData

@Model
final class TherapyProfileEntity {
    @Attribute(.unique) var id: UUID
    var confrontationLevel: Int
    var defaultModesRaw: String
    var morningStart: Date
    var morningEnd: Date
    var middayStart: Date
    var middayEnd: Date
    var eveningStart: Date
    var eveningEnd: Date

    init(profile: TherapyProfile) {
        self.id = UUID()
        self.confrontationLevel = profile.confrontationLevel
        self.defaultModesRaw = profile.defaultModes.map(\.rawValue).joined(separator: ",")
        self.morningStart = profile.morningWindow.start
        self.morningEnd = profile.morningWindow.end
        self.middayStart = profile.middayWindow.start
        self.middayEnd = profile.middayWindow.end
        self.eveningStart = profile.eveningWindow.start
        self.eveningEnd = profile.eveningWindow.end
    }

    var profile: TherapyProfile {
        let modes = defaultModesRaw
            .split(separator: ",")
            .compactMap { InterventionMode(rawValue: String($0)) }

        return TherapyProfile(
            confrontationLevel: confrontationLevel,
            defaultModes: modes.isEmpty ? [.blended] : modes,
            morningWindow: DateInterval(start: morningStart, end: morningEnd),
            middayWindow: DateInterval(start: middayStart, end: middayEnd),
            eveningWindow: DateInterval(start: eveningStart, end: eveningEnd)
        )
    }
}

@Model
final class CommitmentEntity {
    @Attribute(.unique) var id: UUID
    var statement: String
    var nextAction: String
    var durationMinutes: Int
    var dueAt: Date
    var accountabilityPrompt: String
    var statusRaw: String
    var slotRaw: String
    var createdAt: Date

    init(contract: CommitmentContract, slot: RitualSlot) {
        self.id = contract.id
        self.statement = contract.statement
        self.nextAction = contract.nextAction
        self.durationMinutes = contract.durationMinutes
        self.dueAt = contract.dueAt
        self.accountabilityPrompt = contract.accountabilityPrompt
        self.statusRaw = contract.status.rawValue
        self.slotRaw = slot.rawValue
        self.createdAt = .now
    }

    var contract: CommitmentContract {
        CommitmentContract(
            id: id,
            statement: statement,
            nextAction: nextAction,
            durationMinutes: durationMinutes,
            dueAt: dueAt,
            accountabilityPrompt: accountabilityPrompt,
            status: CommitmentStatus(rawValue: statusRaw) ?? .planned
        )
    }

    var slot: RitualSlot {
        RitualSlot(rawValue: slotRaw) ?? .morning
    }
}

@Model
final class TherapySessionEntity {
    @Attribute(.unique) var id: UUID
    var phaseRaw: String
    var slotRaw: String
    var inputText: String
    var rawReality: String
    var reframing: String
    var meaningAnchor: String
    var distortionTagsRaw: String
    var underControlRaw: String
    var notUnderControlRaw: String
    var avoidanceScore: Double
    var followupQuestion: String
    var createdAt: Date

    init(turn: TherapyTurnEnvelope, input: String, slot: RitualSlot, phase: SessionPhase) {
        self.id = UUID()
        self.phaseRaw = phase.rawValue
        self.slotRaw = slot.rawValue
        self.inputText = input
        self.rawReality = turn.rawReality
        self.reframing = turn.reframing
        self.meaningAnchor = turn.meaningAnchor
        self.distortionTagsRaw = turn.diagnosis.distortionTags.joined(separator: "|")
        self.underControlRaw = turn.diagnosis.controlSplit.underControl.joined(separator: "|")
        self.notUnderControlRaw = turn.diagnosis.controlSplit.notUnderControl.joined(separator: "|")
        self.avoidanceScore = turn.diagnosis.avoidanceScore
        self.followupQuestion = turn.followupQuestion
        self.createdAt = .now
    }
}

@Model
final class DailyReviewEntity {
    @Attribute(.unique) var id: UUID
    var date: Date
    var winsRaw: String
    var frictionsRaw: String
    var lesson: String
    var adjustmentForTomorrow: String
    var consistencyScore: Int

    init(
        date: Date,
        wins: [String],
        frictions: [String],
        lesson: String,
        adjustmentForTomorrow: String,
        consistencyScore: Int
    ) {
        self.id = UUID()
        self.date = date
        self.winsRaw = wins.joined(separator: "|")
        self.frictionsRaw = frictions.joined(separator: "|")
        self.lesson = lesson
        self.adjustmentForTomorrow = adjustmentForTomorrow
        self.consistencyScore = consistencyScore
    }
}

@Model
final class MetricEventEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var value: Double
    var context: String
    var createdAt: Date

    init(name: String, value: Double, context: String) {
        self.id = UUID()
        self.name = name
        self.value = value
        self.context = context
        self.createdAt = .now
    }
}

@Model
final class IntegrationQueueItemEntity {
    @Attribute(.unique) var id: UUID
    var kind: String
    var payload: String
    var retries: Int
    var lastError: String
    var createdAt: Date

    init(kind: String, payload: String) {
        self.id = UUID()
        self.kind = kind
        self.payload = payload
        self.retries = 0
        self.lastError = ""
        self.createdAt = .now
    }
}
