import SwiftUI

struct Theme {
    static let background = Color("Background")
    static let primary = Color("Primary")
    static let secondary = Color("Secondary")
    static let accent = Color("Accent")
    
    static let fontName = "Avenir Next"
    
    struct Colors {
        static let chatBubbleUser = Color.blue.opacity(0.8)
        static let chatBubbleAssistant = Color(UIColor.systemGray6)
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
    }
}

extension View {
    func premiumBackground() -> some View {
        self.background(
            LinearGradient(gradient: Gradient(colors: [Color.black, Color(UIColor.darkGray)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
}
