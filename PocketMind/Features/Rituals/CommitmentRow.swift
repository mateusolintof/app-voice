import SwiftUI
import SwiftData

struct CommitmentRow: View {
    let commitment: CommitmentEntity
    let onStatusChange: (CommitmentStatus) -> Void

    private var currentStatus: CommitmentStatus {
        CommitmentStatus(rawValue: commitment.statusRaw) ?? .planned
    }

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                // Status circle — tappable to advance
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onStatusChange(nextStatus)
                } label: {
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.15))
                            .frame(width: 32, height: 32)

                        Image(systemName: iconFor(currentStatus))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(statusColor)
                    }
                }
                .buttonStyle(PressScaleButtonStyle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(commitment.statement)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(PMDesign.textPrimary)
                        .strikethrough(currentStatus == .completed, color: PMDesign.textTertiary)
                        .lineLimit(2)

                    Text(commitment.nextAction)
                        .font(.caption)
                        .foregroundStyle(PMDesign.textSecondary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Label("\(commitment.durationMinutes) min", systemImage: "clock")
                        HStack(spacing: 2) {
                            Image(systemName: "calendar")
                            Text(commitment.dueAt, format: .dateTime.hour().minute())
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(PMDesign.textTertiary)
                }

                Spacer()

                // Status badge
                Text(currentStatus.title)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .foregroundStyle(statusColor)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    private var statusColor: Color {
        switch currentStatus {
        case .planned: return PMDesign.textTertiary
        case .inProgress: return PMDesign.brandPrimary
        case .completed: return PMDesign.success
        case .deferred: return PMDesign.warning
        }
    }

    private var nextStatus: CommitmentStatus {
        switch currentStatus {
        case .planned: return .inProgress
        case .inProgress: return .completed
        case .completed: return .completed
        case .deferred: return .inProgress
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
