import SwiftUI

struct MoodSelectorRow: View {
    @Binding var selectedMood: MoodOption?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Como voce esta?")
                .font(PMDesign.captionRounded)
                .foregroundStyle(PMDesign.textSecondary)

            HStack(spacing: 8) {
                ForEach(MoodOption.allCases) { mood in
                    moodChip(mood)
                }
            }
        }
    }

    private func moodChip(_ mood: MoodOption) -> some View {
        let isSelected = selectedMood == mood

        return Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(PMDesign.springSnappy) {
                selectedMood = isSelected ? nil : mood
            }
        } label: {
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.title3)
                Text(mood.label)
                    .font(PMDesign.caption2Rounded)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? PMDesign.brandPrimary.opacity(0.15) : Color.clear)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: PMDesign.cornerSmall, style: .continuous)
                    .stroke(isSelected ? PMDesign.brandPrimary : Color.clear, lineWidth: 1.5)
            )
            .foregroundStyle(isSelected ? PMDesign.brandPrimary : PMDesign.textSecondary)
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}
