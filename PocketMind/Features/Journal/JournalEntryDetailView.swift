import SwiftUI

struct JournalEntryDetailView: View {
    let entry: JournalEntryEntity

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

                    if let mood = entry.moodTag, !mood.isEmpty {
                        Text(mood)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(PMDesign.accent.opacity(0.15))
                            .foregroundStyle(PMDesign.accent)
                            .clipShape(Capsule())
                    }
                }

                // User bubble
                VStack(alignment: .leading, spacing: 6) {
                    Label("Voce", systemImage: "person.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PMDesign.textSecondary)

                    Text(entry.transcribedText)
                        .font(.body)
                        .padding(PMDesign.spacingM)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerMedium, style: .continuous))
                }

                // AI coach bubble
                if let aiResponse = entry.aiResponse, !aiResponse.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Coach", systemImage: "brain.head.profile.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PMDesign.accent)

                        Text(aiResponse)
                            .font(.body)
                            .padding(PMDesign.spacingM)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(PMDesign.accent.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerMedium, style: .continuous))
                    }
                }

                // Cognitive diagnosis
                if let rawReality = entry.rawReality, !rawReality.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Realidade Crua", systemImage: "eye.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(PMDesign.warning)
                            Text(rawReality)
                                .font(.subheadline)
                                .foregroundStyle(PMDesign.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if let reframing = entry.reframing, !reframing.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Reenquadramento", systemImage: "arrow.triangle.2.circlepath")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(PMDesign.success)
                            Text(reframing)
                                .font(.subheadline)
                                .foregroundStyle(PMDesign.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if let meaning = entry.meaningAnchor, !meaning.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Ancora de Sentido", systemImage: "anchor.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(PMDesign.accent)
                            Text(meaning)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(PMDesign.accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Distortion tags
                if !entry.distortionTags.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Distorcoes Cognitivas", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption.weight(.semibold))
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
                }
            }
            .padding(.horizontal, PMDesign.spacingM)
            .padding(.bottom, PMDesign.spacingXL)
        }
        .background(PMDesign.background)
        .navigationTitle("Entrada")
        .navigationBarTitleDisplayMode(.inline)
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
