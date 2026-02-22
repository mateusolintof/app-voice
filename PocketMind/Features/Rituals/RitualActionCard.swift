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
                    .font(PMDesign.headlineRounded)
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

                // Primary action: Ritual (full-width gradient)
                GlassButton(
                    title: "Ritual",
                    icon: "sun.horizon.fill",
                    style: .primary,
                    isLoading: isProcessing
                ) {
                    onRunRitual()
                }

                // Secondary actions: half-width
                HStack(spacing: 10) {
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onToggleRecording()
                    } label: {
                        Label(isRecording ? "Parar" : "Gravar", systemImage: isRecording ? "stop.fill" : "mic.fill")
                            .font(.caption.weight(.semibold))
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.white)
                            .background(isRecording ? PMDesign.danger : PMDesign.brandPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerSmall, style: .continuous))
                    }
                    .buttonStyle(PressScaleButtonStyle())

                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onRunDiagnosis()
                    } label: {
                        Label("Diagnostico", systemImage: "brain.head.profile")
                            .font(.caption.weight(.semibold))
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(PMDesign.brandPrimary)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerSmall, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: PMDesign.cornerSmall, style: .continuous)
                                    .stroke(PMDesign.glassBorderGradient(opacity: 0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .disabled(isProcessing)
                }

                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onRunRecovery()
                } label: {
                    Label("Recovery 90s", systemImage: "bolt.heart.fill")
                        .font(.caption.weight(.semibold))
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(PMDesign.brandPrimary)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerSmall, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: PMDesign.cornerSmall, style: .continuous)
                                .stroke(PMDesign.glassBorderGradient(opacity: 0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(PressScaleButtonStyle())
                .disabled(isProcessing)

                // Results
                if let turn = lastTurn {
                    resultSection(turn: turn)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
    }

    @ViewBuilder
    private func resultSection(turn: TherapyTurnEnvelope) -> some View {
        Divider()
            .padding(.vertical, 4)

        if !turn.reframing.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Label("Reenquadramento", systemImage: "arrow.triangle.2.circlepath")
                    .font(PMDesign.captionRounded)
                    .foregroundStyle(PMDesign.success)
                Text(turn.reframing)
                    .font(.subheadline)
            }
        }

        if !turn.meaningAnchor.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Label("Ancora de Sentido", systemImage: "anchor.fill")
                    .font(PMDesign.captionRounded)
                    .foregroundStyle(PMDesign.brandPrimary)
                Text(turn.meaningAnchor)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PMDesign.brandPrimary)
            }
        }

        if !turn.contract.statement.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Label("Compromisso", systemImage: "checkmark.seal.fill")
                    .font(PMDesign.captionRounded)
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
                    .font(PMDesign.captionRounded)
                    .foregroundStyle(PMDesign.textSecondary)
                Text(turn.followupQuestion)
                    .font(.subheadline)
                    .italic()
            }
        }
    }
}
