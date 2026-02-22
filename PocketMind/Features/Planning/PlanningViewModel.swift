import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class PlanningViewModel {
    var newStatement: String = ""
    var newAction: String = ""
    var durationMinutes: Int = 15
    var dueAt: Date = Date().addingTimeInterval(60 * 60)

    var statusMessage: String = ""
    var isSyncing = false

    private let syncService = IntegrationSyncService()

    func createManualCommitment(slot: RitualSlot, modelContext: ModelContext) {
        let statement = newStatement.trimmingCharacters(in: .whitespacesAndNewlines)
        let action = newAction.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !statement.isEmpty, !action.isEmpty else {
            statusMessage = "Preencha compromisso e próxima ação."
            return
        }

        let contract = CommitmentContract(
            statement: statement,
            nextAction: action,
            durationMinutes: max(5, min(durationMinutes, 60)),
            dueAt: dueAt,
            accountabilityPrompt: "Você executou a ação combinada?",
            status: .planned
        )

        TherapyRepository.upsertCommitment(contract, slot: slot, in: modelContext)
        TherapyRepository.logMetric(name: "manual_commitment_created", value: 1, context: slot.rawValue, in: modelContext)

        newStatement = ""
        newAction = ""
        durationMinutes = 15
        dueAt = Date().addingTimeInterval(60 * 60)
        statusMessage = "Compromisso criado."
    }

    func markStatus(_ commitment: CommitmentEntity, status: CommitmentStatus, modelContext: ModelContext) {
        TherapyRepository.updateCommitmentStatus(id: commitment.id, status: status, in: modelContext)
        TherapyRepository.logMetric(name: "commitment_status_change", value: 1, context: status.rawValue, in: modelContext)
    }

    func sync(_ commitment: CommitmentEntity, modelContext: ModelContext) async {
        isSyncing = true
        defer { isSyncing = false }

        let googleKey = UserDefaults.standard.string(forKey: "googleCalendarKey") ?? ""
        let linearKey = UserDefaults.standard.string(forKey: "linearKey") ?? ""

        await syncService.sync(
            contract: commitment.contract,
            googleCalendarKey: googleKey,
            linearKey: linearKey,
            modelContext: modelContext
        )

        statusMessage = "Tentativa de sincronização executada."
    }

    func retryQueued(modelContext: ModelContext) async {
        isSyncing = true
        defer { isSyncing = false }

        let googleKey = UserDefaults.standard.string(forKey: "googleCalendarKey") ?? ""
        let linearKey = UserDefaults.standard.string(forKey: "linearKey") ?? ""

        await syncService.retryQueued(
            googleCalendarKey: googleKey,
            linearKey: linearKey,
            modelContext: modelContext
        )

        statusMessage = "Fila de integração processada."
    }
}
