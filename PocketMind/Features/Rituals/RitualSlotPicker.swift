import SwiftUI

struct RitualSlotPicker: View {
    @Binding var selectedSlot: RitualSlot

    var body: some View {
        HStack(spacing: 12) {
            ForEach(RitualSlot.allCases) { slot in
                let isSelected = selectedSlot == slot

                Button {
                    withAnimation(.spring(response: 0.35)) {
                        selectedSlot = slot
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: iconFor(slot))
                            .font(.title3)
                        Text(slot.title)
                            .font(.caption.weight(.semibold))
                        Text(slot.durationHint)
                            .font(.caption2)
                            .foregroundStyle(isSelected ? .white.opacity(0.7) : PMDesign.textTertiary)
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(isSelected ? .white : PMDesign.textPrimary)
                    .background {
                        if isSelected {
                            PMDesign.brandGradient
                        } else {
                            Rectangle().fill(.ultraThinMaterial)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerMedium, style: .continuous))
                }
                .buttonStyle(.plain)
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
