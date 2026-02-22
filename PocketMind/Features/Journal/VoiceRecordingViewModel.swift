import Foundation
import SwiftData
import Observation

enum RecordingState {
    case idle
    case recording
    case transcribing
    case transcribed
    case processingAI
    case complete
}

@MainActor
@Observable
final class VoiceRecordingViewModel {
    var state: RecordingState = .idle
    var transcribedText: String = ""
    var aiResponse: String = ""
    var lastTurn: TherapyTurnEnvelope?
    var errorMessage: String?
    var recordingDuration: TimeInterval = 0

    let audioRecorder = AudioRecorder()
    private let openAIClient = OpenAIClient()
    private let therapyEngine: TherapyEngine = OpenAITherapyEngine()
    private var durationTimer: Timer?

    var audioLevels: [CGFloat] {
        audioRecorder.audioLevels
    }

    var isProcessing: Bool {
        state == .transcribing || state == .processingAI
    }

    func startRecording() {
        Task {
            let permission = await audioRecorder.checkMicrophonePermission()
            guard permission == .granted else {
                errorMessage = "Permissao de microfone negada. Ative em Ajustes > Privacidade > Microfone."
                return
            }

            audioRecorder.startRecording()
            state = .recording
            recordingDuration = 0
            errorMessage = nil

            durationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.recordingDuration += 1
                }
            }
        }
    }

    func stopRecording() {
        audioRecorder.stopRecording()
        durationTimer?.invalidate()
        durationTimer = nil
        state = .transcribing
        transcribe()
    }

    func reRecord() {
        audioRecorder.stopRecording()
        durationTimer?.invalidate()
        durationTimer = nil
        transcribedText = ""
        aiResponse = ""
        lastTurn = nil
        errorMessage = nil
        recordingDuration = 0
        state = .idle
    }

    func sendToCoach(modelContext: ModelContext) async {
        let text = transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            errorMessage = "Escreva ou grave algo antes de enviar."
            return
        }

        state = .processingAI
        errorMessage = nil

        do {
            let context = buildContext(modelContext: modelContext)
            let turn = try await therapyEngine.runTurn(input: text, context: context)
            lastTurn = turn
            aiResponse = formatAIResponse(turn)
            state = .complete
        } catch {
            errorMessage = "Falha ao consultar coach: \(error.localizedDescription)"
            state = .transcribed
        }
    }

    func saveToJournal(modelContext: ModelContext) {
        let audioPath = audioRecorder.persistAudio()

        JournalRepository.saveEntry(
            transcribedText: transcribedText,
            audioFilePath: audioPath,
            aiResponse: aiResponse.isEmpty ? nil : aiResponse,
            turn: lastTurn,
            slot: detectCurrentSlot(),
            in: modelContext
        )

        if let turn = lastTurn {
            TherapyRepository.storeSession(
                turn: turn,
                input: transcribedText,
                slot: detectCurrentSlot(),
                phase: .intervention,
                in: modelContext
            )
            TherapyRepository.upsertCommitment(
                turn.contract,
                slot: detectCurrentSlot(),
                in: modelContext
            )
        }

        TherapyRepository.logMetric(
            name: "journal_entry_saved",
            value: 1,
            context: detectCurrentSlot().rawValue,
            in: modelContext
        )

        reset()
    }

    func reset() {
        durationTimer?.invalidate()
        durationTimer = nil
        state = .idle
        transcribedText = ""
        aiResponse = ""
        lastTurn = nil
        errorMessage = nil
        recordingDuration = 0
    }

    // MARK: - Private

    private func transcribe() {
        guard let fileURL = audioRecorder.recordingURL else {
            errorMessage = "Arquivo de audio indisponivel."
            state = .idle
            return
        }

        let key = UserDefaults.standard.string(forKey: "openAIKey") ?? ""
        guard !key.isEmpty else {
            errorMessage = "Configure sua chave OpenAI em Perfil."
            state = .idle
            return
        }

        Task {
            do {
                let transcript = try await openAIClient.transcribeAudio(fileURL: fileURL, apiKey: key)
                transcribedText = transcript
                state = .transcribed
            } catch {
                errorMessage = "Falha na transcricao: \(error.localizedDescription)"
                state = .idle
            }
        }
    }

    private func buildContext(modelContext: ModelContext) -> TherapyContext {
        let profile = TherapyRepository.currentProfile(in: modelContext)
        let pending = TherapyRepository.fetchCommitments(for: Date(), in: modelContext)
            .map(\.contract)
            .filter { $0.status != .completed }

        return TherapyContext(
            profile: profile,
            activeSlot: detectCurrentSlot(),
            currentMission: "",
            pendingCommitments: pending,
            recentFrictionNotes: []
        )
    }

    private func detectCurrentSlot() -> RitualSlot {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .midday
        default: return .evening
        }
    }

    private func formatAIResponse(_ turn: TherapyTurnEnvelope) -> String {
        var parts: [String] = []

        if !turn.reframing.isEmpty {
            parts.append(turn.reframing)
        }

        if !turn.meaningAnchor.isEmpty {
            parts.append("\n\nAncora: \(turn.meaningAnchor)")
        }

        if !turn.contract.statement.isEmpty {
            parts.append("\n\nCompromisso: \(turn.contract.statement)")
            parts.append("Proxima acao: \(turn.contract.nextAction)")
        }

        if !turn.followupQuestion.isEmpty {
            parts.append("\n\n\(turn.followupQuestion)")
        }

        return parts.joined()
    }

    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
