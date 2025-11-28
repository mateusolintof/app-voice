import SwiftUI

// MARK: - Colors & Gradients
struct PremiumTheme {
    static let background = Color(uiColor: .systemBackground) // Dark mode friendly
    static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    
    static let gradientStart = Color.purple
    static let gradientEnd = Color.blue
    static let mainGradient = LinearGradient(colors: [gradientStart, gradientEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    
    static let neonGlow = Color.blue.opacity(0.5)
}

// MARK: - Modifiers

struct GlassyBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func glassyStyle() -> some View {
        modifier(GlassyBackground())
    }
}

// MARK: - Components

struct PremiumCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(
                ZStack {
                    Color(uiColor: .secondarySystemGroupedBackground)
                    
                    // Subtle gradient border effect
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.1), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

struct PremiumButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var color: Color = .blue
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 2)
        }
    }
}
