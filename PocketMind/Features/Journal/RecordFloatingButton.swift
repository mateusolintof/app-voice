import SwiftUI

struct RecordFloatingButton: View {
    let onTap: () -> Void
    @State private var isPulsing = false

    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onTap()
        } label: {
            ZStack {
                // Pulsing outer ring
                Circle()
                    .stroke(PMDesign.brandPrimary.opacity(isPulsing ? 0 : 0.6), lineWidth: 2)
                    .frame(width: 78, height: 78)
                    .scaleEffect(isPulsing ? 1.25 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: isPulsing)

                // Main button
                Image(systemName: "mic.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(PMDesign.brandGradient)
                    .clipShape(Circle())
                    .shadow(color: PMDesign.brandPrimary.opacity(0.3), radius: 8, y: 4)
                    .shadow(color: PMDesign.brandPrimary.opacity(0.15), radius: 16, y: 8)
            }
        }
        .buttonStyle(PressScaleButtonStyle())
        .onAppear {
            isPulsing = true
        }
    }
}
