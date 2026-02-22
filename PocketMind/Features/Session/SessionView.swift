import SwiftUI
import SwiftData

struct SessionView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SessionViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VoiceTherapyConsole(
                        selectedSlot: $viewModel.selectedSlot,
                        transcribedText: $viewModel.transcribedText,
                        isRecording: viewModel.isRecording,
                        isProcessing: viewModel.isProcessing,
                        onToggleRecording: { viewModel.toggleRecording() },
                        onRunTurn: {
                            Task { await viewModel.runTherapyTurn(modelContext: modelContext) }
                        },
                        onRunRitual: {
                            Task { await viewModel.runRitual(modelContext: modelContext) }
                        },
                        onRunRecovery: {
                            Task { await viewModel.runRecovery(modelContext: modelContext) }
                        }
                    )

                    if let error = viewModel.errorMessage, !error.isEmpty {
                        Text(error)
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }

                    if let turn = viewModel.lastTurn {
                        DistortionRadarCard(tags: turn.diagnosis.distortionTags, avoidanceScore: turn.diagnosis.avoidanceScore)
                        ControlSplitCard(split: turn.diagnosis.controlSplit)
                        MeaningAnchorCard(rawReality: turn.rawReality, reframing: turn.reframing, meaning: turn.meaningAnchor)

                        CommitmentContractCard(contract: turn.contract) {
                            TherapyRepository.upsertCommitment(turn.contract, slot: viewModel.selectedSlot, in: modelContext)
                            TherapyRepository.logMetric(name: "contract_saved_from_session", value: 1, context: viewModel.selectedSlot.rawValue, in: modelContext)
                        }

                        FollowupCard(question: turn.followupQuestion)
                    }

                    if let recovery = viewModel.lastRecovery {
                        RecoverySprintCard(recovery: recovery)
                    }
                }
                .padding()
            }
            .background(CognitiveTheme.canvas.ignoresSafeArea())
            .navigationTitle("Sessão")
        }
    }
}

private struct VoiceTherapyConsole: View {
    @Binding var selectedSlot: RitualSlot
    @Binding var transcribedText: String

    let isRecording: Bool
    let isProcessing: Bool
    let onToggleRecording: () -> Void
    let onRunTurn: () -> Void
    let onRunRitual: () -> Void
    let onRunRecovery: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Voice Therapy Console")
                    .font(.system(.title3, design: .serif).weight(.bold))
                    .foregroundStyle(CognitiveTheme.ink)

                Spacer()

                Text(selectedSlot.durationHint)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(CognitiveTheme.mutedInk)
            }

            Picker("Ritual", selection: $selectedSlot) {
                ForEach(RitualSlot.allCases) { slot in
                    Text(slot.title).tag(slot)
                }
            }
            .pickerStyle(.segmented)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $transcribedText)
                    .frame(minHeight: 140)
                    .font(.system(.body, design: .rounded))
                    .scrollContentBackground(.hidden)
                    .padding(4)
                    .background(CognitiveTheme.surfaceStrong.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if transcribedText.isEmpty {
                    Text("Fale livremente. O parceiro vai confrontar distorções e fechar em ação real.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(CognitiveTheme.mutedInk)
                        .padding(.top, 12)
                        .padding(.leading, 10)
                        .allowsHitTesting(false)
                }
            }

            HStack(spacing: 10) {
                Button(action: onToggleRecording) {
                    Label(isRecording ? "Parar" : "Gravar", systemImage: isRecording ? "stop.fill" : "mic.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TherapyActionButtonStyle(color: isRecording ? .red : CognitiveTheme.action))

                Button(action: onRunTurn) {
                    Label("Diagnóstico", systemImage: "brain.head.profile")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TherapyActionButtonStyle(color: CognitiveTheme.action))
            }

            HStack(spacing: 10) {
                Button(action: onRunRitual) {
                    Label("Rodar Ritual", systemImage: "sun.horizon")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TherapyActionButtonStyle(color: CognitiveTheme.warning))

                Button(action: onRunRecovery) {
                    Label("Recovery 90s", systemImage: "bolt.heart")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TherapyActionButtonStyle(color: CognitiveTheme.success))
            }

            if isProcessing {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Processando intervenção terapêutica...")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(CognitiveTheme.mutedInk)
                }
            }
        }
        .therapyCard()
    }
}

private struct DistortionRadarCard: View {
    let tags: [String]
    let avoidanceScore: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Distortion Radar")
                .font(.system(.headline, design: .serif).weight(.semibold))

            if tags.isEmpty {
                Text("Sem distorções destacadas no último turno.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(CognitiveTheme.mutedInk)
            } else {
                FlexibleTagWrap(tags: tags)
            }

            HStack {
                Text("Score de fuga")
                    .font(.system(.caption, design: .rounded))
                Spacer()
                Text(String(format: "%.2f", avoidanceScore))
                    .font(.system(.caption, design: .monospaced))
            }
            .foregroundStyle(CognitiveTheme.mutedInk)
        }
        .therapyCard()
    }
}

private struct ControlSplitCard: View {
    let split: ControlSplit

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Control Split")
                .font(.system(.headline, design: .serif).weight(.semibold))

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sob controle")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(CognitiveTheme.success)
                    ForEach(split.underControl, id: \.self) { item in
                        Text("• \(item)")
                            .font(.system(.caption, design: .rounded))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Fora de controle")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(CognitiveTheme.warning)
                    ForEach(split.notUnderControl, id: \.self) { item in
                        Text("• \(item)")
                            .font(.system(.caption, design: .rounded))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(CognitiveTheme.ink)
        }
        .therapyCard()
    }
}

private struct MeaningAnchorCard: View {
    let rawReality: String
    let reframing: String
    let meaning: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Meaning Anchor")
                .font(.system(.headline, design: .serif).weight(.semibold))

            Text("Fato cru: \(rawReality)")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(CognitiveTheme.ink)

            Text("Reenquadramento: \(reframing)")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(CognitiveTheme.ink)

            Text("Sentido: \(meaning)")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(CognitiveTheme.action)
        }
        .therapyCard()
    }
}

private struct CommitmentContractCard: View {
    let contract: CommitmentContract
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Commitment Contract")
                .font(.system(.headline, design: .serif).weight(.semibold))

            Text(contract.statement)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))

            Text("Próxima ação: \(contract.nextAction)")
                .font(.system(.subheadline, design: .rounded))

            HStack {
                Label("\(contract.durationMinutes) min", systemImage: "timer")
                Spacer()
                Label(contract.dueAt.formatted(date: .omitted, time: .shortened), systemImage: "calendar")
            }
            .font(.system(.caption, design: .rounded))
            .foregroundStyle(CognitiveTheme.mutedInk)

            Text(contract.accountabilityPrompt)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(CognitiveTheme.action)

            Button(action: onSave) {
                Label("Salvar no Planejamento", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(TherapyActionButtonStyle(color: CognitiveTheme.action))
        }
        .therapyCard()
    }
}

private struct FollowupCard: View {
    let question: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cobrança do próximo check-in")
                .font(.system(.headline, design: .serif).weight(.semibold))
            Text(question)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(CognitiveTheme.ink)
        }
        .therapyCard()
    }
}

private struct RecoverySprintCard: View {
    let recovery: RecoveryOutput

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recovery Sprint Wizard")
                .font(.system(.headline, design: .serif).weight(.semibold))

            Text(recovery.summary)
                .font(.system(.subheadline, design: .rounded))

            Text("Ação de reset: \(recovery.resetAction)")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(CognitiveTheme.success)
        }
        .therapyCard()
    }
}

private struct FlexibleTagWrap: View {
    let tags: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(CognitiveTheme.surfaceStrong.opacity(0.6))
                    .clipShape(Capsule())
            }
        }
    }
}
