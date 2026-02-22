import SwiftUI

struct JournalEntryCard: View {
    let entry: JournalEntryEntity

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // Top row: time + mood
                HStack {
                    Text(entry.createdAt, format: .dateTime.hour().minute())
                        .font(.caption.weight(.medium))
                        .foregroundStyle(PMDesign.textTertiary)

                    if entry.audioFilePath != nil {
                        Image(systemName: "waveform")
                            .font(.caption2)
                            .foregroundStyle(PMDesign.accent)
                    }

                    Spacer()

                    if let mood = entry.moodTag, !mood.isEmpty {
                        Text(mood)
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(PMDesign.accent.opacity(0.15))
                            .foregroundStyle(PMDesign.accent)
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
                            .foregroundStyle(PMDesign.accent)

                        Text(aiResponse)
                            .font(.caption)
                            .foregroundStyle(PMDesign.textSecondary)
                            .lineLimit(2)
                    }
                    .padding(10)
                    .background(PMDesign.accent.opacity(0.06))
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
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
