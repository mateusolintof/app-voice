import SwiftUI
import SwiftData

struct RitualsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = RitualsViewModel()
    @State private var showReview = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: PMDesign.spacingL) {
                    // Slot picker
                    RitualSlotPicker(selectedSlot: $vm.selectedSlot)

                    // Ritual action card
                    RitualActionCard(
                        inputText: $vm.transcribedText,
                        isRecording: vm.isRecording,
                        isProcessing: vm.isProcessing,
                        lastTurn: vm.lastTurn,
                        lastRitual: vm.lastRitual,
                        lastRecovery: vm.lastRecovery,
                        onToggleRecording: { vm.toggleRecording() },
                        onRunDiagnosis: {
                            Task { await vm.runTherapyTurn(modelContext: modelContext) }
                        },
                        onRunRitual: {
                            Task { await vm.runRitual(modelContext: modelContext) }
                        },
                        onRunRecovery: {
                            Task { await vm.runRecovery(modelContext: modelContext) }
                        }
                    )

                    // Commitments section
                    VStack(alignment: .leading, spacing: PMDesign.spacingS) {
                        HStack {
                            Text("Compromissos Ativos")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(PMDesign.textPrimary)

                            Spacer()

                            Button {
                                withAnimation(.spring(response: 0.35)) {
                                    vm.showNewCommitment.toggle()
                                }
                            } label: {
                                Image(systemName: vm.showNewCommitment ? "xmark.circle.fill" : "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(PMDesign.accent)
                            }
                        }

                        // New commitment form
                        if vm.showNewCommitment {
                            newCommitmentForm
                        }

                        if vm.todayCommitments.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "checkmark.seal")
                                        .font(.title2)
                                        .foregroundStyle(PMDesign.textTertiary)
                                    Text("Nenhum compromisso para hoje")
                                        .font(.caption)
                                        .foregroundStyle(PMDesign.textTertiary)
                                }
                                .padding(.vertical, PMDesign.spacingL)
                                Spacer()
                            }
                        } else {
                            ForEach(vm.todayCommitments, id: \.id) { commitment in
                                CommitmentRow(commitment: commitment) { status in
                                    vm.markStatus(commitment, status: status, modelContext: modelContext)
                                }
                            }
                        }
                    }

                    // Evening review button
                    if vm.selectedSlot == .evening {
                        GlassButton(title: "Revisao do Dia", icon: "moon.stars.fill", style: .primary) {
                            showReview = true
                        }
                    }
                }
                .padding(.horizontal, PMDesign.spacingM)
                .padding(.bottom, PMDesign.spacingXL)
            }
            .background(PMDesign.background)
            .navigationTitle("Rituais")
            .sheet(isPresented: $showReview) {
                QuickReviewSheet(completionRate: vm.completionRate())
            }
            .onAppear {
                vm.loadCommitments(modelContext: modelContext)
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
    }

    // MARK: - New Commitment Form

    private var newCommitmentForm: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: PMDesign.spacingS) {
                Label("Novo Compromisso", systemImage: "plus.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PMDesign.accent)

                TextField("Compromisso", text: $vm.newStatement)
                    .font(.subheadline)
                    .padding(PMDesign.spacingS)
                    .background(PMDesign.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerSmall, style: .continuous))

                TextField("Proxima acao (max 15 min)", text: $vm.newAction)
                    .font(.subheadline)
                    .padding(PMDesign.spacingS)
                    .background(PMDesign.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerSmall, style: .continuous))

                HStack {
                    Stepper("Duracao: \(vm.durationMinutes) min", value: $vm.durationMinutes, in: 5...60, step: 5)
                        .font(.caption)
                }

                DatePicker("Prazo", selection: $vm.dueAt, displayedComponents: [.date, .hourAndMinute])
                    .font(.caption)

                GlassButton(title: "Criar Compromisso", icon: "checkmark", style: .primary) {
                    vm.createCommitment(modelContext: modelContext)
                }
            }
        }
    }
}
