import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(sort: [SortDescriptor(\CommitmentEntity.dueAt)]) private var commitments: [CommitmentEntity]
    @State private var energyLevel: Double = 3

    private var todayCommitments: [CommitmentEntity] {
        commitments
            .filter { Calendar.current.isDateInToday($0.dueAt) }
            .sorted { $0.dueAt < $1.dueAt }
    }

    private var mainMission: String {
        todayCommitments.first?.statement ?? "Defina a missão principal na sessão da manhã."
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    DailyCommandCenterCard(
                        mission: mainMission,
                        commitments: Array(todayCommitments.prefix(3))
                    )

                    EnergyMeterCard(energyLevel: $energyLevel)

                    FocusRibbonCard(commitments: todayCommitments)
                }
                .padding()
            }
            .background(CognitiveTheme.canvas.ignoresSafeArea())
            .navigationTitle("Hoje")
        }
    }
}

private struct DailyCommandCenterCard: View {
    let mission: String
    let commitments: [CommitmentEntity]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Daily Command Center")
                .font(.system(.title3, design: .serif).weight(.bold))
                .foregroundStyle(CognitiveTheme.ink)

            Text(mission)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(CognitiveTheme.ink)

            ForEach(commitments, id: \.id) { item in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(statusColor(item.statusRaw))
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.statement)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(CognitiveTheme.ink)

                        Text("Próxima ação: \(item.nextAction)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(CognitiveTheme.mutedInk)
                    }

                    Spacer()
                }
            }

            if commitments.isEmpty {
                Text("Sem compromissos para hoje. Abra a aba Sessão e rode o ritual da manhã.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(CognitiveTheme.mutedInk)
            }
        }
        .therapyCard()
    }

    private func statusColor(_ raw: String) -> Color {
        switch CommitmentStatus(rawValue: raw) {
        case .completed: return CognitiveTheme.success
        case .inProgress: return CognitiveTheme.action
        case .deferred: return CognitiveTheme.warning
        default: return CognitiveTheme.mutedInk.opacity(0.5)
        }
    }
}

private struct EnergyMeterCard: View {
    @Binding var energyLevel: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cognitive Energy Meter")
                .font(.system(.headline, design: .serif).weight(.semibold))
                .foregroundStyle(CognitiveTheme.ink)

            Slider(value: $energyLevel, in: 1...5, step: 1)
                .tint(CognitiveTheme.action)

            Text("Nível atual: \(Int(energyLevel))/5")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(CognitiveTheme.mutedInk)
        }
        .therapyCard()
    }
}

private struct FocusRibbonCard: View {
    let commitments: [CommitmentEntity]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus Ribbon")
                .font(.system(.headline, design: .serif).weight(.semibold))
                .foregroundStyle(CognitiveTheme.ink)

            if commitments.isEmpty {
                Text("O ribbon aparece quando você criar compromissos no planejamento.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(CognitiveTheme.mutedInk)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(commitments, id: \.id) { commitment in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(commitment.dueAt.formatted(date: .omitted, time: .shortened))
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(CognitiveTheme.mutedInk)

                                Text(commitment.statement)
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                                    .lineLimit(2)
                                    .foregroundStyle(CognitiveTheme.ink)
                            }
                            .padding(10)
                            .frame(width: 170, alignment: .leading)
                            .background(CognitiveTheme.surfaceStrong.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
        .therapyCard()
    }
}
