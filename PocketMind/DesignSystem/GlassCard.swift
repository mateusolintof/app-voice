import SwiftUI

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = PMDesign.cornerMedium
    var material: Material = .ultraThinMaterial
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(PMDesign.spacingM)
            .background(material)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

#Preview {
    ZStack {
        PMDesign.brandGradient.ignoresSafeArea()

        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Glass Card")
                    .font(.headline)
                Text("Conteudo de exemplo")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
}
