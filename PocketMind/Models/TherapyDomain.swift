import Foundation

enum SessionPhase: String, Codable, CaseIterable, Identifiable {
    case intake
    case diagnosis
    case intervention
    case commitment
    case followup
    case review

    var id: String { rawValue }
}

enum InterventionMode: String, Codable, CaseIterable, Identifiable {
    case cbt
    case stoic
    case logotherapy
    case blended

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cbt: return "CBT"
        case .stoic: return "Estoicismo"
        case .logotherapy: return "Logoterapia"
        case .blended: return "Combinado"
        }
    }
}

enum RitualSlot: String, Codable, CaseIterable, Identifiable {
    case morning
    case midday
    case evening

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning: return "Manhã"
        case .midday: return "Meio do dia"
        case .evening: return "Noite"
        }
    }

    var durationHint: String {
        switch self {
        case .morning: return "5-8 min"
        case .midday: return "2-4 min"
        case .evening: return "6-10 min"
        }
    }
}

enum CommitmentStatus: String, Codable, CaseIterable, Identifiable {
    case planned
    case inProgress
    case completed
    case deferred

    var id: String { rawValue }

    var title: String {
        switch self {
        case .planned: return "Planejado"
        case .inProgress: return "Em andamento"
        case .completed: return "Concluído"
        case .deferred: return "Adiado"
        }
    }
}

struct ControlSplit: Codable, Hashable {
    var underControl: [String]
    var notUnderControl: [String]

    static let empty = ControlSplit(underControl: [], notUnderControl: [])
}

struct TherapyProfile: Codable {
    var confrontationLevel: Int
    var defaultModes: [InterventionMode]
    var morningWindow: DateInterval
    var middayWindow: DateInterval
    var eveningWindow: DateInterval

    static var `default`: TherapyProfile {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        return TherapyProfile(
            confrontationLevel: 4,
            defaultModes: [.blended, .cbt, .stoic, .logotherapy],
            morningWindow: DateInterval(start: calendar.date(byAdding: .hour, value: 7, to: startOfDay) ?? startOfDay,
                                        end: calendar.date(byAdding: .hour, value: 11, to: startOfDay) ?? startOfDay),
            middayWindow: DateInterval(start: calendar.date(byAdding: .hour, value: 12, to: startOfDay) ?? startOfDay,
                                       end: calendar.date(byAdding: .hour, value: 15, to: startOfDay) ?? startOfDay),
            eveningWindow: DateInterval(start: calendar.date(byAdding: .hour, value: 19, to: startOfDay) ?? startOfDay,
                                        end: calendar.date(byAdding: .hour, value: 22, to: startOfDay) ?? startOfDay)
        )
    }
}

struct CognitiveDiagnosis: Codable {
    var distortionTags: [String]
    var controlSplit: ControlSplit
    var avoidanceScore: Double
}

struct CommitmentContract: Identifiable, Codable, Hashable {
    var id: UUID
    var statement: String
    var nextAction: String
    var durationMinutes: Int
    var dueAt: Date
    var accountabilityPrompt: String
    var status: CommitmentStatus

    init(
        id: UUID = UUID(),
        statement: String,
        nextAction: String,
        durationMinutes: Int,
        dueAt: Date,
        accountabilityPrompt: String,
        status: CommitmentStatus = .planned
    ) {
        self.id = id
        self.statement = statement
        self.nextAction = nextAction
        self.durationMinutes = durationMinutes
        self.dueAt = dueAt
        self.accountabilityPrompt = accountabilityPrompt
        self.status = status
    }
}

struct TherapyTurnEnvelope: Codable {
    var rawReality: String
    var diagnosis: CognitiveDiagnosis
    var reframing: String
    var meaningAnchor: String
    var contract: CommitmentContract
    var followupQuestion: String
}

struct TherapyContext: Codable {
    var profile: TherapyProfile
    var activeSlot: RitualSlot
    var currentMission: String
    var pendingCommitments: [CommitmentContract]
    var recentFrictionNotes: [String]

    static var empty: TherapyContext {
        TherapyContext(
            profile: .default,
            activeSlot: .morning,
            currentMission: "",
            pendingCommitments: [],
            recentFrictionNotes: []
        )
    }
}

struct RitualOutput: Codable {
    var slot: RitualSlot
    var summary: String
    var mission: String
    var contract: CommitmentContract
    var accountabilityPrompt: String
}

struct RecoveryOutput: Codable {
    var summary: String
    var frictionDetected: [String]
    var resetAction: String
    var contract: CommitmentContract
}

protocol TherapyEngine {
    func runTurn(input: String, context: TherapyContext) async throws -> TherapyTurnEnvelope
    func runRitual(slot: RitualSlot, context: TherapyContext) async throws -> RitualOutput
    func runRecovery(context: TherapyContext) async throws -> RecoveryOutput
}
