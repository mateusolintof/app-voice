import SwiftUI
import SwiftData

struct VoiceRecordingSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var vm = VoiceRecordingViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                PMDesign.background.ignoresSafeArea()

                switch vm.state {
                case .idle:
                    idleView
                case .recording:
                    recordingView
                case .transcribing:
                    processingView(message: "Transcrevendo...")
                case .transcribed:
                    transcribedView
                case .processingAI:
                    processingView(message: "Coach pensando...")
                case .complete:
                    completeView
                }
            }
            .navigationTitle("Gravar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") {
                        vm.reset()
                        dismiss()
                    }
                }
            }
            .alert("Erro", isPresented: .init(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(vm.state == .recording)
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "waveform.and.mic")
                .font(.system(size: 48))
                .foregroundStyle(PMDesign.textTertiary)

            Text("Toque para comecar a gravar")
                .font(.subheadline)
                .foregroundStyle(PMDesign.textSecondary)

            recordButton(isRecording: false)

            Spacer()
        }
    }

    // MARK: - Recording

    private var recordingView: some View {
        VStack(spacing: 32) {
            Spacer()

            Text(vm.formattedDuration)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundStyle(PMDesign.textPrimary)
                .contentTransition(.numericText())

            WaveformView(levels: vm.audioLevels)
                .frame(height: 80)
                .padding(.horizontal, 40)

            stopButton

            Spacer()
        }
    }

    // MARK: - Processing

    private func processingView(message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(PMDesign.textSecondary)
            Spacer()
        }
    }

    // MARK: - Transcribed

    private var transcribedView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Voce disse:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PMDesign.textSecondary)

                TextEditor(text: $vm.transcribedText)
                    .font(.body)
                    .frame(minHeight: 150)
                    .padding(PMDesign.spacingS)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerMedium, style: .continuous))

                GlassButton(title: "Enviar para Coach", icon: "brain.head.profile", style: .primary) {
                    Task {
                        await vm.sendToCoach(modelContext: modelContext)
                    }
                }

                GlassButton(title: "Salvar sem Coach", icon: "square.and.arrow.down", style: .secondary) {
                    vm.saveToJournal(modelContext: modelContext)
                    dismiss()
                }
            }
            .padding(PMDesign.spacingM)
        }
    }

    // MARK: - Complete

    private var completeView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // User text
                VStack(alignment: .leading, spacing: 6) {
                    Label("Voce", systemImage: "person.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PMDesign.textSecondary)

                    Text(vm.transcribedText)
                        .font(.body)
                        .padding(PMDesign.spacingM)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerMedium, style: .continuous))
                }

                // AI response
                VStack(alignment: .leading, spacing: 6) {
                    Label("Coach", systemImage: "brain.head.profile.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PMDesign.accent)

                    Text(vm.aiResponse)
                        .font(.body)
                        .padding(PMDesign.spacingM)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PMDesign.accent.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerMedium, style: .continuous))
                }

                // Distortion tags
                if let turn = vm.lastTurn, !turn.diagnosis.distortionTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(turn.diagnosis.distortionTags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(PMDesign.warning.opacity(0.12))
                                    .foregroundStyle(PMDesign.warning)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Commitment
                if let turn = vm.lastTurn, !turn.contract.statement.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Compromisso", systemImage: "checkmark.seal.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(PMDesign.success)

                            Text(turn.contract.statement)
                                .font(.subheadline.weight(.medium))

                            Text(turn.contract.nextAction)
                                .font(.caption)
                                .foregroundStyle(PMDesign.textSecondary)

                            HStack {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                Text("\(turn.contract.durationMinutes) min")
                                    .font(.caption)
                            }
                            .foregroundStyle(PMDesign.textTertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                GlassButton(title: "Salvar no Diario", icon: "square.and.arrow.down", style: .primary) {
                    vm.saveToJournal(modelContext: modelContext)
                    dismiss()
                }
            }
            .padding(PMDesign.spacingM)
        }
    }

    // MARK: - Buttons

    private func recordButton(isRecording: Bool) -> some View {
        Button {
            vm.startRecording()
        } label: {
            ZStack {
                Circle()
                    .fill(PMDesign.brandGradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: PMDesign.accent.opacity(0.4), radius: 16)

                Image(systemName: "mic.fill")
                    .font(.title)
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }

    private var stopButton: some View {
        Button {
            vm.stopRecording()
        } label: {
            ZStack {
                Circle()
                    .fill(PMDesign.danger)
                    .frame(width: 80, height: 80)
                    .shadow(color: PMDesign.danger.opacity(0.4), radius: 16)

                RoundedRectangle(cornerRadius: 8)
                    .fill(.white)
                    .frame(width: 28, height: 28)
            }
        }
        .buttonStyle(.plain)
    }
}
