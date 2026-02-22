import SwiftUI
import SwiftData

struct ReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ReviewViewModel()

    @Query(sort: [SortDescriptor(\CommitmentEntity.dueAt)])
    private var commitments: [CommitmentEntity]

    private var todayCommitments: [CommitmentEntity] {
        commitments.filter { Calendar.current.isDateInToday($0.dueAt) }
    }

    private var completionRate: Double {
        viewModel.completionRate(for: todayCommitments)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    EveningReviewLedgerCard(
                        total: todayCommitments.count,
                        completionRate: completionRate
                    )

                    ReviewInputCard(
                        winsInput: $viewModel.winsInput,
                        frictionsInput: $viewModel.frictionsInput,
                        lesson: $viewModel.lesson,
                        adjustment: $viewModel.adjustment,
                        consistencyScore: $viewModel.consistencyScore,
                        onSave: { viewModel.saveReview(modelContext: modelContext) }
                    )

                    if !viewModel.statusMessage.isEmpty {
                        Text(viewModel.statusMessage)
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(CognitiveTheme.mutedInk)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    ReflectionTimelineCard(commitments: todayCommitments)
                }
                .padding()
            }
            .background(CognitiveTheme.canvas.ignoresSafeArea())
            .navigationTitle("Revisão")
        }
    }
}

private struct EveningReviewLedgerCard: View {
    let total: Int
    let completionRate: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Evening Review Ledger")
                .font(.system(.title3, design: .serif).weight(.bold))

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Compromissos hoje")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(CognitiveTheme.mutedInk)
                    Text("\(total)")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Conclusão")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(CognitiveTheme.mutedInk)
                    Text("\(Int(completionRate * 100))%")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                }
            }
        }
        .therapyCard()
    }
}

private struct ReviewInputCard: View {
    @Binding var winsInput: String
    @Binding var frictionsInput: String
    @Binding var lesson: String
    @Binding var adjustment: String
    @Binding var consistencyScore: Double

    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reflection Input")
                .font(.system(.headline, design: .serif).weight(.semibold))

            TextField("Vitórias (separe por vírgula)", text: $winsInput)
                .textFieldStyle(.roundedBorder)

            TextField("Fricções (separe por vírgula)", text: $frictionsInput)
                .textFieldStyle(.roundedBorder)

            TextField("Lição do dia", text: $lesson)
                .textFieldStyle(.roundedBorder)

            TextField("Ajuste para amanhã", text: $adjustment)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 6) {
                Text("Consistência do ritual: \(Int(consistencyScore))/5")
                    .font(.system(.caption, design: .rounded))
                Slider(value: $consistencyScore, in: 1...5, step: 1)
                    .tint(CognitiveTheme.action)
            }

            Button(action: onSave) {
                Label("Salvar Revisão", systemImage: "checkmark.seal.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(TherapyActionButtonStyle(color: CognitiveTheme.action))
        }
        .therapyCard()
    }
}

private struct ReflectionTimelineCard: View {
    let commitments: [CommitmentEntity]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reflection Timeline")
                .font(.system(.headline, design: .serif).weight(.semibold))

            if commitments.isEmpty {
                Text("Sem eventos no timeline de hoje.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(CognitiveTheme.mutedInk)
            } else {
                ForEach(commitments, id: \.id) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(color(for: item.statusRaw))
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.statement)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))

                            Text("\(item.dueAt.formatted(date: .omitted, time: .shortened)) • \(CommitmentStatus(rawValue: item.statusRaw)?.title ?? "Planejado")")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(CognitiveTheme.mutedInk)
                        }
                    }
                }
            }
        }
        .therapyCard()
    }

    private func color(for rawStatus: String) -> Color {
        switch CommitmentStatus(rawValue: rawStatus) {
        case .completed: return CognitiveTheme.success
        case .inProgress: return CognitiveTheme.action
        case .deferred: return CognitiveTheme.warning
        default: return CognitiveTheme.mutedInk.opacity(0.5)
        }
    }
}
