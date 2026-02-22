import SwiftUI

struct RitualSlotPicker: View {
    @Binding var selectedSlot: RitualSlot
    @Namespace private var slotNamespace

    var body: some View {
        HStack(spacing: 12) {
            ForEach(RitualSlot.allCases) { slot in
                let isSelected = selectedSlot == slot

                Button {
                    let generator = UISelectionFeedbackGenerator()
                    generator.selectionChanged()
                    withAnimation(PMDesign.springSnappy) {
                        selectedSlot = slot
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: iconFor(slot))
                            .font(.title3)
                            .symbolEffect(.bounce, value: selectedSlot == slot)
                        Text(slot.title)
                            .font(PMDesign.captionRounded)
                        Text(slot.durationHint)
                            .font(PMDesign.caption2Rounded)
                            .foregroundStyle(isSelected ? .white.opacity(0.7) : PMDesign.textTertiary)
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(isSelected ? .white : PMDesign.textPrimary)
                    .background {
                        if isSelected {
                            PMDesign.brandGradient
                                .matchedGeometryEffect(id: "slotHighlight", in: slotNamespace)
                                .overlay(
                                    RoundedRectangle(cornerRadius: PMDesign.cornerMedium, style: .continuous)
                                        .stroke(PMDesign.brandPrimary.opacity(0.4), lineWidth: 1)
                                        .blur(radius: 4)
                                )
                        } else {
                            Rectangle().fill(.ultraThinMaterial)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerMedium, style: .continuous))
                }
                .buttonStyle(PressScaleButtonStyle())
            }
        }
    }

    private func iconFor(_ slot: RitualSlot) -> String {
        switch slot {
        case .morning: return "sun.max.fill"
        case .midday: return "sun.min.fill"
        case .evening: return "moon.stars.fill"
        }
    }
}
