import SwiftUI

struct JournalEntryCard: View {
    let entry: JournalEntryEntity

    var body: some View {
        GlassCard {
            HStack(spacing: 0) {
                // Left accent bar
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(slotGradient)
                    .frame(width: 3)
                    .padding(.vertical, -PMDesign.spacingM)
                    .padding(.leading, -PMDesign.spacingM)
                    .padding(.trailing, 12)

                VStack(alignment: .leading, spacing: 10) {
                    // Top row: time + mood
                    HStack {
                        Text(entry.createdAt, format: .dateTime.hour().minute())
                            .font(PMDesign.caption2Rounded)
                            .foregroundStyle(PMDesign.textTertiary)

                        if entry.audioFilePath != nil {
                            Image(systemName: "waveform")
                                .font(.caption2)
                                .foregroundStyle(PMDesign.brandPrimary)
                        }

                        Spacer()

                        if let mood = entry.moodTag, !mood.isEmpty {
                            Text(mood)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(PMDesign.brandGradient.opacity(0.2))
                                .foregroundStyle(PMDesign.brandPrimary)
                                .clipShape(Capsule())
                        }
                    }

                    // Transcribed text
                    Text(entry.transcribedText)
                        .font(.subheadline)
                        .foregroundStyle(PMDesign.textPrimary)
                        .lineLimit(3)

                    // AI response preview
                    if let aiResponse = entry.aiResponse, !aiResponse.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "brain.head.profile.fill")
                                .font(.caption)
                                .foregroundStyle(PMDesign.brandPrimary)

                            Text(aiResponse)
                                .font(.caption)
                                .foregroundStyle(PMDesign.textSecondary)
                                .lineLimit(2)
                        }
                        .padding(10)
                        .background(PMDesign.brandPrimary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    // Distortion tags
                    if !entry.distortionTags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(entry.distortionTags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(PMDesign.warning.opacity(0.1))
                                    .foregroundStyle(PMDesign.warning)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var slotGradient: LinearGradient {
        switch entry.slot {
        case .morning:
            return PMDesign.goldGradient
        case .midday:
            return PMDesign.brandGradient
        case .evening:
            return LinearGradient(
                colors: [PMDesign.brandPrimary, PMDesign.brandPrimary.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}
