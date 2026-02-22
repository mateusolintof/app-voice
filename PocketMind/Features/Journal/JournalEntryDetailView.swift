import SwiftUI

struct JournalEntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let entry: JournalEntryEntity
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Date header
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundStyle(PMDesign.textTertiary)
                    Text(entry.createdAt, format: .dateTime.day().month().year().hour().minute())
                        .font(.subheadline)
                        .foregroundStyle(PMDesign.textSecondary)

                    Spacer()

                    if let mood = entry.moodTag, !mood.isEmpty,
                       let moodOption = MoodOption(rawValue: mood) {
                        Text("\(moodOption.emoji) \(moodOption.label)")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(PMDesign.brandGradient.opacity(0.2))
                            .foregroundStyle(PMDesign.brandPrimary)
                            .clipShape(Capsule())
                    }
                }

                // Audio player
                if let audioPath = entry.audioFilePath, !audioPath.isEmpty {
                    AudioPlayerView(audioFilePath: audioPath)
                }

                // User bubble
                VStack(alignment: .leading, spacing: 6) {
                    Label("Voce", systemImage: "person.fill")
                        .font(PMDesign.captionRounded)
                        .foregroundStyle(PMDesign.textSecondary)

                    Text(entry.transcribedText)
                        .font(.body)
                        .padding(PMDesign.spacingM)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerMedium, style: .continuous))
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                // AI coach bubble
                if let aiResponse = entry.aiResponse, !aiResponse.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Coach", systemImage: "brain.head.profile.fill")
                            .font(PMDesign.captionRounded)
                            .foregroundStyle(PMDesign.brandPrimary)

                        Text(aiResponse)
                            .font(.body)
                            .padding(PMDesign.spacingM)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(PMDesign.brandPrimary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerMedium, style: .continuous))
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                }

                // Raw Reality
                if let rawReality = entry.rawReality, !rawReality.isEmpty {
                    sectionCard(
                        title: "Realidade Crua",
                        icon: "eye.fill",
                        color: PMDesign.accentAmber,
                        text: rawReality,
                        delay: 0.1
                    )
                }

                // Reframing
                if let reframing = entry.reframing, !reframing.isEmpty {
                    sectionCard(
                        title: "Reenquadramento",
                        icon: "arrow.triangle.2.circlepath",
                        color: PMDesign.success,
                        text: reframing,
                        delay: 0.2
                    )
                }

                // Meaning Anchor
                if let meaning = entry.meaningAnchor, !meaning.isEmpty {
                    GlassCard(glowColor: PMDesign.accentGold, glowOpacity: 0.3) {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Ancora de Sentido", systemImage: "anchor.fill")
                                .font(PMDesign.captionRounded)
                                .foregroundStyle(PMDesign.accentGold)
                            Text(meaning)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(PMDesign.brandPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                }

                // Distortion tags
                if !entry.distortionTags.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Distorcoes Cognitivas", systemImage: "exclamationmark.triangle.fill")
                                .font(PMDesign.captionRounded)
                                .foregroundStyle(PMDesign.warning)

                            FlowLayout(spacing: 6) {
                                ForEach(entry.distortionTags, id: \.self) { tag in
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                }

                // Linked commitment
                if let commitmentId = entry.commitmentId,
                   let commitment = TherapyRepository.fetchCommitment(id: commitmentId, in: modelContext) {
                    let status = CommitmentStatus(rawValue: commitment.statusRaw) ?? .planned
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Compromisso Relacionado", systemImage: "link")
                                .font(PMDesign.captionRounded)
                                .foregroundStyle(PMDesign.brandPrimary)

                            Text(commitment.statement)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(PMDesign.textPrimary)

                            Text(commitment.nextAction)
                                .font(.caption)
                                .foregroundStyle(PMDesign.textSecondary)

                            Text(status.title)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .foregroundStyle(status == .completed ? PMDesign.success : PMDesign.brandPrimary)
                                .background((status == .completed ? PMDesign.success : PMDesign.brandPrimary).opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                }
            }
            .padding(.horizontal, PMDesign.spacingM)
            .padding(.bottom, PMDesign.spacingXL)
        }
        .background(PMDesign.background)
        .navigationTitle("Entrada")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(PMDesign.springGentle.delay(0.15)) {
                appeared = true
            }
        }
    }

    @ViewBuilder
    private func sectionCard(title: String, icon: String, color: Color, text: String, delay: Double) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label(title, systemImage: icon)
                    .font(PMDesign.captionRounded)
                    .foregroundStyle(color)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(PMDesign.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }
}

// MARK: - Flow Layout for tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
