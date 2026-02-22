import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class RitualsViewModel {
    var selectedSlot: RitualSlot = .morning
    var transcribedText: String = ""
    var currentMission: String = ""

    var isRecording = false
    var isProcessing = false
    var errorMessage: String?

    var lastTurn: TherapyTurnEnvelope?
    var lastRitual: RitualOutput?
    var lastRecovery: RecoveryOutput?

    var todayCommitments: [CommitmentEntity] = []

    // Commitment creation
    var newStatement: String = ""
    var newAction: String = ""
    var durationMinutes: Int = 15
    var dueAt: Date = Date().addingTimeInterval(60 * 60)
    var showNewCommitment = false

    private let audioRecorder = AudioRecorder()
    private let openAIClient = OpenAIClient()
    private let therapyEngine: TherapyEngine = OpenAITherapyEngine()

    func loadCommitments(modelContext: ModelContext) {
        todayCommitments = TherapyRepository.fetchCommitments(for: Date(), in: modelContext)
    }

    // MARK: - Recording

    func toggleRecording() {
        if audioRecorder.isRecording {
            audioRecorder.stopRecording()
            isRecording = false
            processRecording()
        } else {
            Task {
                let permission = await audioRecorder.checkMicrophonePermission()
                guard permission == .granted else {
                    errorMessage = "Permissao de microfone negada. Ative em Ajustes > Privacidade > Microfone."
                    return
                }
                audioRecorder.startRecording()
                isRecording = true
                errorMessage = nil
            }
        }
    }

    // MARK: - Therapy Actions

    func runTherapyTurn(modelContext: ModelContext) async {
        guard !transcribedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Grave ou digite algo antes de rodar a sessao."
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let context = buildContext(modelContext: modelContext)
            let turn = try await therapyEngine.runTurn(input: transcribedText, context: context)

            lastTurn = turn
            currentMission = turn.meaningAnchor

            TherapyRepository.storeSession(
                turn: turn, input: transcribedText,
                slot: selectedSlot, phase: .intervention,
                in: modelContext
            )
            TherapyRepository.upsertCommitment(turn.contract, slot: selectedSlot, in: modelContext)
            TherapyRepository.logMetric(name: "session_turn_completed", value: 1, context: selectedSlot.rawValue, in: modelContext)

            transcribedText = ""
            loadCommitments(modelContext: modelContext)
        } catch {
            errorMessage = "Falha ao executar sessao: \(error.localizedDescription)"
        }
    }

    func runRitual(modelContext: ModelContext) async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            let context = buildContext(modelContext: modelContext)
            let ritual = try await therapyEngine.runRitual(slot: selectedSlot, context: context)

            lastRitual = ritual
            lastTurn = TherapyTurnEnvelope(
                rawReality: ritual.summary,
                diagnosis: CognitiveDiagnosis(
                    distortionTags: ["ritual_\(selectedSlot.rawValue)"],
                    controlSplit: .empty,
                    avoidanceScore: 0
                ),
                reframing: ritual.summary,
                meaningAnchor: ritual.mission,
                contract: ritual.contract,
                followupQuestion: ritual.accountabilityPrompt
            )

            currentMission = ritual.mission
            TherapyRepository.upsertCommitment(ritual.contract, slot: selectedSlot, in: modelContext)
            TherapyRepository.logMetric(name: "ritual_completed", value: 1, context: selectedSlot.rawValue, in: modelContext)

            loadCommitments(modelContext: modelContext)
        } catch {
            errorMessage = "Falha no ritual: \(error.localizedDescription)"
        }
    }

    func runRecovery(modelContext: ModelContext) async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            let context = buildContext(modelContext: modelContext)
            let recovery = try await therapyEngine.runRecovery(context: context)
            lastRecovery = recovery
            lastTurn = TherapyTurnEnvelope(
                rawReality: recovery.summary,
                diagnosis: CognitiveDiagnosis(
                    distortionTags: recovery.frictionDetected,
                    controlSplit: .empty,
                    avoidanceScore: 0.2
                ),
                reframing: recovery.summary,
                meaningAnchor: "Retomar execucao com intencao clara.",
                contract: recovery.contract,
                followupQuestion: "Voce consegue iniciar isso agora?"
            )

            TherapyRepository.upsertCommitment(recovery.contract, slot: selectedSlot, in: modelContext)
            TherapyRepository.logMetric(name: "recovery_completed", value: 1, context: selectedSlot.rawValue, in: modelContext)

            loadCommitments(modelContext: modelContext)
        } catch {
            errorMessage = "Falha no recovery sprint: \(error.localizedDescription)"
        }
    }

    // MARK: - Commitments

    func createCommitment(modelContext: ModelContext) {
        let statement = newStatement.trimmingCharacters(in: .whitespacesAndNewlines)
        let action = newAction.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !statement.isEmpty, !action.isEmpty else {
            errorMessage = "Preencha compromisso e proxima acao."
            return
        }

        let contract = CommitmentContract(
            statement: statement,
            nextAction: action,
            durationMinutes: max(5, min(durationMinutes, 60)),
            dueAt: dueAt,
            accountabilityPrompt: "Voce executou a acao combinada?",
            status: .planned
        )

        TherapyRepository.upsertCommitment(contract, slot: selectedSlot, in: modelContext)
        TherapyRepository.logMetric(name: "manual_commitment_created", value: 1, context: selectedSlot.rawValue, in: modelContext)

        newStatement = ""
        newAction = ""
        durationMinutes = 15
        dueAt = Date().addingTimeInterval(60 * 60)
        showNewCommitment = false
        loadCommitments(modelContext: modelContext)
    }

    func markStatus(_ commitment: CommitmentEntity, status: CommitmentStatus, modelContext: ModelContext) {
        TherapyRepository.updateCommitmentStatus(id: commitment.id, status: status, in: modelContext)
        TherapyRepository.logMetric(name: "commitment_status_change", value: 1, context: status.rawValue, in: modelContext)
        loadCommitments(modelContext: modelContext)
    }

    func completionRate() -> Double {
        guard !todayCommitments.isEmpty else { return 0 }
        let done = todayCommitments.filter { CommitmentStatus(rawValue: $0.statusRaw) == .completed }.count
        return Double(done) / Double(todayCommitments.count)
    }

    // MARK: - Private

    private func processRecording() {
        guard let fileURL = audioRecorder.recordingURL else {
            errorMessage = "Arquivo de audio indisponivel."
            return
        }

        let key = UserDefaults.standard.string(forKey: "openAIKey") ?? ""
        guard !key.isEmpty else {
            errorMessage = "Configure sua chave OpenAI em Perfil."
            return
        }

        isProcessing = true

        Task {
            defer { isProcessing = false }

            do {
                let transcript = try await openAIClient.transcribeAudio(fileURL: fileURL, apiKey: key)
                transcribedText = transcript
            } catch {
                errorMessage = "Falha na transcricao: \(error.localizedDescription)"
            }
        }
    }

    private func buildContext(modelContext: ModelContext) -> TherapyContext {
        let profile = TherapyRepository.currentProfile(in: modelContext)
        let pending = TherapyRepository.fetchCommitments(for: Date(), in: modelContext)
            .map(\.contract)
            .filter { $0.status != .completed }

        let frictions = fetchRecentFrictions(modelContext: modelContext)

        return TherapyContext(
            profile: profile,
            activeSlot: selectedSlot,
            currentMission: currentMission,
            pendingCommitments: pending,
            recentFrictionNotes: frictions
        )
    }

    private func fetchRecentFrictions(modelContext: ModelContext) -> [String] {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: Date())) ?? Date()

        let descriptor = FetchDescriptor<DailyReviewEntity>(
            predicate: #Predicate { $0.date >= sevenDaysAgo },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let reviews = try? modelContext.fetch(descriptor) else { return [] }

        return reviews
            .flatMap { $0.frictionsRaw.split(separator: "|").map(String.init) }
            .filter { !$0.isEmpty }
    }
}
