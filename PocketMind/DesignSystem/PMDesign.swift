import SwiftUI

enum PMDesign {

    // MARK: - Brand Colors

    static let brandPrimary = Color(hex: 0x5933E6)
    static let brandSecondary = Color(hex: 0x6699FF)
    static let brandTertiary = Color(hex: 0x8CD9F2)
    static let accentGold = Color(hex: 0xFFC752)
    static let accentAmber = Color(hex: 0xFF9933)

    // MARK: - Semantic Colors (auto dark mode)

    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)

    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)

    // MARK: - Status Colors

    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red

    // MARK: - Gradients

    static let brandGradient = LinearGradient(
        colors: [brandPrimary, brandSecondary, brandTertiary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let subtleGradient = LinearGradient(
        colors: [brandPrimary.opacity(0.12), brandSecondary.opacity(0.06)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldGradient = LinearGradient(
        colors: [accentGold, accentAmber],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let waveformGradient = LinearGradient(
        colors: [brandPrimary, brandSecondary, brandTertiary],
        startPoint: .leading,
        endPoint: .trailing
    )

    static func glassBorderGradient(opacity: Double = 0.25) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(opacity),
                Color.white.opacity(opacity * 0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Corner Radii

    static let cornerSmall: CGFloat = 12
    static let cornerMedium: CGFloat = 16
    static let cornerLarge: CGFloat = 24

    // MARK: - Spacing

    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32

    // MARK: - Typography

    static let heroNumber: Font = .system(size: 56, weight: .ultraLight, design: .rounded)
    static let largeTitleRounded: Font = .largeTitle.weight(.bold).rounded()
    static let title1: Font = .title.weight(.bold).rounded()
    static let title2: Font = .title2.weight(.semibold).rounded()
    static let title3: Font = .title3.weight(.semibold).rounded()
    static let headlineRounded: Font = .headline.weight(.semibold).rounded()
    static let subheadlineRounded: Font = .subheadline.weight(.medium).rounded()
    static let bodyRounded: Font = .body.rounded()
    static let captionRounded: Font = .caption.weight(.medium).rounded()
    static let caption2Rounded: Font = .caption2.weight(.medium).rounded()
    static let mono: Font = .system(.body, design: .monospaced)

    // MARK: - Animations

    static let springSnappy = Animation.spring(response: 0.35, dampingFraction: 0.75)
    static let springGentle = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
}

// MARK: - Font Extension for Rounded

private extension Font {
    func rounded() -> Font {
        self.width(.standard)
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

// MARK: - Soft Shadow Modifier

struct SoftShadowModifier: ViewModifier {
    var radius: CGFloat = 16
    var color: Color = .black.opacity(0.08)

    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: radius / 3, x: 0, y: 2)
            .shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 8)
    }
}

extension View {
    func softShadow(radius: CGFloat = 16, color: Color = .black.opacity(0.08)) -> some View {
        modifier(SoftShadowModifier(radius: radius, color: color))
    }
}

// MARK: - Animated Mesh Background

struct AnimatedMeshBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            MeshCanvas(time: timeline.date.timeIntervalSinceReferenceDate)
        }
        .ignoresSafeArea()
    }
}

private struct MeshCanvas: View {
    let time: TimeInterval

    var body: some View {
        Canvas { context, size in
            let rect = Path(CGRect(origin: .zero, size: size))
            drawBlob(context: &context, rect: rect, size: size, color: PMDesign.brandPrimary, xFactor: 0.3, yFactor: 0.25, xAmp: 0.15, yAmp: 0.1, xFreq: 0.4, yFreq: 0.3, radiusFactor: 0.6)
            drawBlob(context: &context, rect: rect, size: size, color: PMDesign.brandSecondary, xFactor: 0.7, yFactor: 0.5, xAmp: 0.12, yAmp: 0.15, xFreq: 0.35, yFreq: 0.45, radiusFactor: 0.5)
            drawBlob(context: &context, rect: rect, size: size, color: PMDesign.brandTertiary, xFactor: 0.5, yFactor: 0.75, xAmp: 0.2, yAmp: 0.1, xFreq: 0.25, yFreq: 0.5, radiusFactor: 0.55)
        }
    }

    private func drawBlob(context: inout GraphicsContext, rect: Path, size: CGSize, color: Color, xFactor: Double, yFactor: Double, xAmp: Double, yAmp: Double, xFreq: Double, yFreq: Double, radiusFactor: Double) {
        let cx: CGFloat = size.width * (xFactor + xAmp * sin(time * xFreq))
        let cy: CGFloat = size.height * (yFactor + yAmp * cos(time * yFreq))
        let center = CGPoint(x: cx, y: cy)
        let radius: CGFloat = size.width * radiusFactor

        let gradient = Gradient(colors: [color.opacity(0.3), color.opacity(0.1), color.opacity(0)])
        let shading = GraphicsContext.Shading.radialGradient(gradient, center: center, startRadius: 0, endRadius: radius)
        context.fill(rect, with: shading)
    }
}

// MARK: - Press Scale Button Style

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(PMDesign.springSnappy, value: configuration.isPressed)
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.15),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 400)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
