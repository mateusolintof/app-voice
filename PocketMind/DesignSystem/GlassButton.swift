import SwiftUI

struct GlassButton: View {
    let title: String
    let icon: String
    var style: Style = .primary
    var isLoading: Bool = false
    let action: () -> Void

    enum Style {
        case primary
        case secondary
        case danger
        case gold
    }

    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(foregroundColor)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerSmall, style: .continuous))
            .overlay {
                if style == .secondary {
                    RoundedRectangle(cornerRadius: PMDesign.cornerSmall, style: .continuous)
                        .stroke(PMDesign.glassBorderGradient(opacity: 0.3), lineWidth: 1)
                }
            }
        }
        .buttonStyle(PressScaleButtonStyle())
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            PMDesign.brandGradient
        case .secondary:
            Rectangle().fill(.ultraThinMaterial)
        case .danger:
            LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .top, endPoint: .bottom)
        case .gold:
            PMDesign.goldGradient
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .danger, .gold:
            return .white
        case .secondary:
            return PMDesign.brandPrimary
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        GlassButton(title: "Salvar", icon: "checkmark", style: .primary) {}
        GlassButton(title: "Cancelar", icon: "xmark", style: .secondary) {}
        GlassButton(title: "Apagar", icon: "trash", style: .danger) {}
        GlassButton(title: "Premium", icon: "star.fill", style: .gold) {}
        GlassButton(title: "Carregando", icon: "arrow.clockwise", style: .primary, isLoading: true) {}
    }
    .padding()
}
