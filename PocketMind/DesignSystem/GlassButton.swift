import SwiftUI

struct GlassButton: View {
    let title: String
    let icon: String
    var style: Style = .primary
    let action: () -> Void

    enum Style {
        case primary
        case secondary
        case danger
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(foregroundColor)
                .background(backgroundView)
                .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerSmall, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            PMDesign.brandGradient
        case .secondary:
            Rectangle().fill(.ultraThinMaterial)
        case .danger:
            Color.red
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .danger:
            return .white
        case .secondary:
            return PMDesign.accent
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        GlassButton(title: "Salvar", icon: "checkmark", style: .primary) {}
        GlassButton(title: "Cancelar", icon: "xmark", style: .secondary) {}
        GlassButton(title: "Apagar", icon: "trash", style: .danger) {}
    }
    .padding()
}
