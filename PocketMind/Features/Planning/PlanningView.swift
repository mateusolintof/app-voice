import SwiftUI
import SwiftData

struct PlanningView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PlanningViewModel()
    @State private var selectedSlot: RitualSlot = .morning

    @Query(sort: [SortDescriptor(\CommitmentEntity.dueAt)])
    private var commitments: [CommitmentEntity]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    PlanningComposerCard(
                        selectedSlot: $selectedSlot,
                        newStatement: $viewModel.newStatement,
                        newAction: $viewModel.newAction,
                        durationMinutes: $viewModel.durationMinutes,
                        dueAt: $viewModel.dueAt,
                        onCreate: {
                            viewModel.createManualCommitment(slot: selectedSlot, modelContext: modelContext)
                        }
                    )

                    if !viewModel.statusMessage.isEmpty {
                        Text(viewModel.statusMessage)
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(CognitiveTheme.mutedInk)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task { await viewModel.retryQueued(modelContext: modelContext) }
                    } label: {
                        Label("Reprocessar Fila de Integração", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(TherapyActionButtonStyle(color: CognitiveTheme.warning))

                    VStack(spacing: 12) {
                        ForEach(commitments, id: \.id) { commitment in
                            PlanningCommitmentRow(
                                commitment: commitment,
                                onStatusChange: { status in
                                    viewModel.markStatus(commitment, status: status, modelContext: modelContext)
                                },
                                onSync: {
                                    Task { await viewModel.sync(commitment, modelContext: modelContext) }
                                }
                            )
                        }

                        if commitments.isEmpty {
                            Text("Sem compromissos ainda.")
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(CognitiveTheme.mutedInk)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .therapyCard()
                        }
                    }
                }
                .padding()
            }
            .background(CognitiveTheme.canvas.ignoresSafeArea())
            .navigationTitle("Planejamento")
        }
    }
}

private struct PlanningComposerCard: View {
    @Binding var selectedSlot: RitualSlot
    @Binding var newStatement: String
    @Binding var newAction: String
    @Binding var durationMinutes: Int
    @Binding var dueAt: Date

    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Commitment Contract Builder")
                .font(.system(.title3, design: .serif).weight(.bold))

            Picker("Ritual", selection: $selectedSlot) {
                ForEach(RitualSlot.allCases) { slot in
                    Text(slot.title).tag(slot)
                }
            }
            .pickerStyle(.segmented)

            TextField("Compromisso (ex: fechar proposta do cliente X)", text: $newStatement)
                .textFieldStyle(.roundedBorder)

            TextField("Próxima ação <= 15 min", text: $newAction)
                .textFieldStyle(.roundedBorder)

            HStack {
                Stepper("Duração: \(durationMinutes) min", value: $durationMinutes, in: 5...60, step: 5)
                Spacer()
            }
            .font(.system(.footnote, design: .rounded))
            .foregroundStyle(CognitiveTheme.mutedInk)

            DatePicker("Prazo", selection: $dueAt)
                .datePickerStyle(.compact)

            Button(action: onCreate) {
                Label("Criar Compromisso", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(TherapyActionButtonStyle(color: CognitiveTheme.action))
        }
        .therapyCard()
    }
}

private struct PlanningCommitmentRow: View {
    let commitment: CommitmentEntity
    let onStatusChange: (CommitmentStatus) -> Void
    let onSync: () -> Void

    private var status: CommitmentStatus {
        CommitmentStatus(rawValue: commitment.statusRaw) ?? .planned
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(commitment.statement)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(CognitiveTheme.ink)

                    Text(commitment.nextAction)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(CognitiveTheme.mutedInk)
                }

                Spacer()

                Menu {
                    ForEach(CommitmentStatus.allCases) { next in
                        Button(next.title) {
                            onStatusChange(next)
                        }
                    }
                } label: {
                    Label(status.title, systemImage: "chevron.up.chevron.down")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(CognitiveTheme.action)
                }
            }

            HStack {
                Label("\(commitment.durationMinutes) min", systemImage: "timer")
                Spacer()
                Label(commitment.dueAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
            }
            .font(.system(.caption2, design: .rounded))
            .foregroundStyle(CognitiveTheme.mutedInk)

            Button(action: onSync) {
                Label("Sincronizar Calendar/Tasks", systemImage: "icloud.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(TherapyActionButtonStyle(color: CognitiveTheme.success))
        }
        .therapyCard()
    }
}
