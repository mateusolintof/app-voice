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

enum MoodOption: String, CaseIterable, Identifiable {
    case pesado
    case tenso
    case neutro
    case bem
    case motivado

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .pesado: return "😞"
        case .tenso: return "😕"
        case .neutro: return "😐"
        case .bem: return "😊"
        case .motivado: return "🔥"
        }
    }

    var label: String {
        switch self {
        case .pesado: return "Pesado"
        case .tenso: return "Tenso"
        case .neutro: return "Neutro"
        case .bem: return "Bem"
        case .motivado: return "Motivado"
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Robust UUID: fallback to new UUID if AI returns invalid string
        if let uuidString = try? container.decode(String.self, forKey: .id),
           let uuid = UUID(uuidString: uuidString) {
            self.id = uuid
        } else {
            self.id = UUID()
        }

        self.statement = try container.decode(String.self, forKey: .statement)
        self.nextAction = try container.decode(String.self, forKey: .nextAction)
        self.durationMinutes = (try? container.decode(Int.self, forKey: .durationMinutes)) ?? 15
        self.accountabilityPrompt = (try? container.decode(String.self, forKey: .accountabilityPrompt)) ?? ""

        // Robust Date: try ISO8601 string first, then fallback
        if let dateString = try? container.decode(String.self, forKey: .dueAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                self.dueAt = date
            } else {
                // Try without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                self.dueAt = formatter.date(from: dateString) ?? Date().addingTimeInterval(3600)
            }
        } else {
            self.dueAt = Date().addingTimeInterval(3600)
        }

        let statusRaw = (try? container.decode(String.self, forKey: .status)) ?? "planned"
        self.status = CommitmentStatus(rawValue: statusRaw) ?? .planned
    }

    private enum CodingKeys: String, CodingKey {
        case id, statement, nextAction, durationMinutes, dueAt, accountabilityPrompt, status
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
