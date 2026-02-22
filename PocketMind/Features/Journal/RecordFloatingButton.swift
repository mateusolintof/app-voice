import SwiftUI

struct RecordFloatingButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "mic.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(PMDesign.brandGradient)
                .clipShape(Circle())
                .shadow(color: PMDesign.accent.opacity(0.4), radius: 16, y: 6)
        }
        .buttonStyle(.plain)
    }
}
