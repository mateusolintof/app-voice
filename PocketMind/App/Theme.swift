import SwiftUI

struct CognitiveTheme {
    static let canvas = Color(red: 0.97, green: 0.95, blue: 0.91)
    static let surface = Color(red: 0.93, green: 0.90, blue: 0.84)
    static let surfaceStrong = Color(red: 0.88, green: 0.84, blue: 0.76)
    static let ink = Color(red: 0.16, green: 0.18, blue: 0.20)
    static let mutedInk = Color(red: 0.33, green: 0.34, blue: 0.35)

    static let action = Color(red: 0.12, green: 0.36, blue: 0.46)
    static let warning = Color(red: 0.70, green: 0.43, blue: 0.19)
    static let success = Color(red: 0.23, green: 0.48, blue: 0.33)

    static let gradient = LinearGradient(
        colors: [Color(red: 0.12, green: 0.36, blue: 0.46), Color(red: 0.24, green: 0.47, blue: 0.56)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [Color(red: 0.25, green: 0.36, blue: 0.45), Color(red: 0.46, green: 0.54, blue: 0.42)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct TherapyCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(CognitiveTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(CognitiveTheme.surfaceStrong.opacity(0.8), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func therapyCard() -> some View {
        modifier(TherapyCardModifier())
    }
}

// Legacy compatibility
struct Theme {
    static let background = CognitiveTheme.canvas
    static let primary = CognitiveTheme.ink
    static let secondary = CognitiveTheme.mutedInk
    static let accent = CognitiveTheme.action

    static let fontName = "Avenir Next"

    struct Colors {
        static let chatBubbleUser = CognitiveTheme.action.opacity(0.85)
        static let chatBubbleAssistant = CognitiveTheme.surface
        static let textPrimary = CognitiveTheme.ink
        static let textSecondary = CognitiveTheme.mutedInk
    }
}

extension View {
    func premiumBackground() -> some View {
        background(CognitiveTheme.canvas.ignoresSafeArea())
    }
}
