import Foundation
import SwiftUI
import SwiftData
import Observation

@MainActor
@Observable
final class SessionViewModel {
    var transcribedText: String = ""
    var selectedSlot: RitualSlot = .morning
    var currentMission: String = ""
    var frictionNote: String = ""

    var isRecording = false
    var isProcessing = false
    var errorMessage: String?

    var lastTurn: TherapyTurnEnvelope?
    var lastRitual: RitualOutput?
    var lastRecovery: RecoveryOutput?

    private let audioRecorder = AudioRecorder()
    private let openAIClient = OpenAIClient()
    private let therapyEngine: TherapyEngine = OpenAITherapyEngine()

    func toggleRecording() {
        if audioRecorder.isRecording {
            audioRecorder.stopRecording()
            isRecording = false
            processRecording()
        } else {
            audioRecorder.startRecording()
            isRecording = true
            errorMessage = nil
        }
    }

    func runTherapyTurn(modelContext: ModelContext) async {
        guard !transcribedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Grave ou digite algo antes de rodar a sessão."
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
                turn: turn,
                input: transcribedText,
                slot: selectedSlot,
                phase: .intervention,
                in: modelContext
            )
            TherapyRepository.upsertCommitment(turn.contract, slot: selectedSlot, in: modelContext)
            TherapyRepository.logMetric(name: "session_turn_completed", value: 1, context: selectedSlot.rawValue, in: modelContext)

            transcribedText = ""
        } catch {
            errorMessage = "Falha ao executar sessão: \(error.localizedDescription)"
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
                meaningAnchor: "Retomar execução com intenção clara.",
                contract: recovery.contract,
                followupQuestion: "Você consegue iniciar isso agora?"
            )

            TherapyRepository.upsertCommitment(recovery.contract, slot: selectedSlot, in: modelContext)
            TherapyRepository.logMetric(name: "recovery_completed", value: 1, context: selectedSlot.rawValue, in: modelContext)
        } catch {
            errorMessage = "Falha no recovery sprint: \(error.localizedDescription)"
        }
    }

    private func processRecording() {
        guard let fileURL = audioRecorder.recordingURL else {
            errorMessage = "Arquivo de áudio indisponível."
            return
        }

        let key = UserDefaults.standard.string(forKey: "openAIKey") ?? ""
        guard !key.isEmpty else {
            errorMessage = "Configure sua chave OpenAI em Config."
            return
        }

        isProcessing = true

        Task {
            defer { isProcessing = false }

            do {
                let transcript = try await openAIClient.transcribeAudio(fileURL: fileURL, apiKey: key)
                transcribedText = transcript
            } catch {
                errorMessage = "Falha na transcrição: \(error.localizedDescription)"
            }
        }
    }

    private func buildContext(modelContext: ModelContext) -> TherapyContext {
        let profile = TherapyRepository.currentProfile(in: modelContext)
        let pending = TherapyRepository.fetchCommitments(for: Date(), in: modelContext)
            .map(\.contract)
            .filter { $0.status != .completed }

        let frictions = frictionNote.isEmpty ? [] : [frictionNote]

        return TherapyContext(
            profile: profile,
            activeSlot: selectedSlot,
            currentMission: currentMission,
            pendingCommitments: pending,
            recentFrictionNotes: frictions
        )
    }
}
