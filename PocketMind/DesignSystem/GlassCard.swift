import SwiftUI

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = PMDesign.cornerMedium
    var material: Material = .ultraThinMaterial
    var borderOpacity: Double = 0.25
    var shadowRadius: CGFloat = 16
    var glowColor: Color? = nil
    var glowOpacity: Double = 0.0
    var padding: CGFloat = PMDesign.spacingM
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(material)
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.06),
                                Color.black.opacity(0.03)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(PMDesign.glassBorderGradient(opacity: borderOpacity), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: shadowRadius / 4, x: 0, y: 2)
            .shadow(color: .black.opacity(0.1), radius: shadowRadius, x: 0, y: 8)
            .overlay {
                if let glow = glowColor, glowOpacity > 0 {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(glow.opacity(glowOpacity), lineWidth: 1.5)
                        .blur(radius: 4)
                }
            }
    }
}

#Preview {
    ZStack {
        PMDesign.brandGradient.ignoresSafeArea()

        VStack(spacing: 16) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Glass Card")
                        .font(PMDesign.headlineRounded)
                    Text("Conteudo de exemplo")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GlassCard(glowColor: PMDesign.accentGold, glowOpacity: 0.5) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gold Glow")
                        .font(PMDesign.headlineRounded)
                    Text("Card com brilho dourado")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
    }
}
