import SwiftUI
import SwiftData

struct CommitmentRow: View {
    let commitment: CommitmentEntity
    let onStatusChange: (CommitmentStatus) -> Void

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(commitment.statement)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(PMDesign.textPrimary)
                        .lineLimit(1)

                    Text(commitment.nextAction)
                        .font(.caption)
                        .foregroundStyle(PMDesign.textSecondary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Label("\(commitment.durationMinutes) min", systemImage: "clock")
                        Label(commitment.dueAt, format: .dateTime.hour().minute())
                    }
                    .font(.caption2)
                    .foregroundStyle(PMDesign.textTertiary)
                }

                Spacer()

                Menu {
                    ForEach(CommitmentStatus.allCases) { status in
                        Button {
                            onStatusChange(status)
                        } label: {
                            Label(status.title, systemImage: iconFor(status))
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(PMDesign.textSecondary)
                }
            }
        }
    }

    private var statusColor: Color {
        switch CommitmentStatus(rawValue: commitment.statusRaw) ?? .planned {
        case .planned: return PMDesign.textTertiary
        case .inProgress: return PMDesign.accent
        case .completed: return PMDesign.success
        case .deferred: return PMDesign.warning
        }
    }

    private func iconFor(_ status: CommitmentStatus) -> String {
        switch status {
        case .planned: return "circle"
        case .inProgress: return "arrow.right.circle"
        case .completed: return "checkmark.circle.fill"
        case .deferred: return "pause.circle"
        }
    }
}
