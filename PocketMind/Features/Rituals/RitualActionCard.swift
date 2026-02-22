import SwiftUI
import SwiftData

struct RitualActionCard: View {
    @Binding var inputText: String
    let isRecording: Bool
    let isProcessing: Bool
    let lastTurn: TherapyTurnEnvelope?
    let lastRitual: RitualOutput?
    let lastRecovery: RecoveryOutput?

    let onToggleRecording: () -> Void
    let onRunDiagnosis: () -> Void
    let onRunRitual: () -> Void
    let onRunRecovery: () -> Void

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: PMDesign.spacingM) {
                Label("Entrada de Voz", systemImage: "waveform.and.mic")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PMDesign.textPrimary)

                TextEditor(text: $inputText)
                    .font(.body)
                    .frame(minHeight: 80)
                    .padding(PMDesign.spacingS)
                    .background(PMDesign.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerSmall, style: .continuous))
                    .overlay(
                        Group {
                            if inputText.isEmpty {
                                Text("Fale livremente ou digite aqui...")
                                    .font(.body)
                                    .foregroundStyle(PMDesign.textTertiary)
                                    .padding(.leading, 12)
                                    .padding(.top, 16)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )

                // Action buttons
                HStack(spacing: 10) {
                    Button {
                        onToggleRecording()
                    } label: {
                        Label(isRecording ? "Parar" : "Gravar", systemImage: isRecording ? "stop.fill" : "mic.fill")
                            .font(.caption.weight(.semibold))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .foregroundStyle(.white)
                            .background(isRecording ? PMDesign.danger : PMDesign.accent)
                            .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerSmall, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        onRunDiagnosis()
                    } label: {
                        Label("Diagnostico", systemImage: "brain.head.profile")
                            .font(.caption.weight(.semibold))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .foregroundStyle(.white)
                            .background(PMDesign.accent.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerSmall, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                }

                HStack(spacing: 10) {
                    Button {
                        onRunRitual()
                    } label: {
                        Label("Ritual", systemImage: "sun.horizon.fill")
                            .font(.caption.weight(.semibold))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .foregroundStyle(.white)
                            .background(PMDesign.success)
                            .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerSmall, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)

                    Button {
                        onRunRecovery()
                    } label: {
                        Label("Recovery 90s", systemImage: "bolt.heart.fill")
                            .font(.caption.weight(.semibold))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .foregroundStyle(.white)
                            .background(PMDesign.warning)
                            .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerSmall, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                }

                if isProcessing {
                    HStack {
                        ProgressView()
                        Text("Processando...")
                            .font(.caption)
                            .foregroundStyle(PMDesign.textSecondary)
                    }
                }

                // Results
                if let turn = lastTurn {
                    resultSection(turn: turn)
                }
            }
        }
    }

    @ViewBuilder
    private func resultSection(turn: TherapyTurnEnvelope) -> some View {
        Divider()

        if !turn.reframing.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Label("Reenquadramento", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PMDesign.success)
                Text(turn.reframing)
                    .font(.subheadline)
            }
        }

        if !turn.meaningAnchor.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Label("Ancora de Sentido", systemImage: "anchor.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PMDesign.accent)
                Text(turn.meaningAnchor)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PMDesign.accent)
            }
        }

        if !turn.contract.statement.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Label("Compromisso", systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PMDesign.success)
                Text(turn.contract.statement)
                    .font(.subheadline)
                Text(turn.contract.nextAction)
                    .font(.caption)
                    .foregroundStyle(PMDesign.textSecondary)
            }
        }

        if !turn.followupQuestion.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Label("Proxima Reflexao", systemImage: "questionmark.bubble.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PMDesign.textSecondary)
                Text(turn.followupQuestion)
                    .font(.subheadline)
                    .italic()
            }
        }
    }
}
