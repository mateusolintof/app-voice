import SwiftUI

struct WaveformView: View {
    let levels: [CGFloat]
    var barCount: Int = 48

    // EMA smoothing state
    @State private var smoothedLevels: [CGFloat] = []
    private let smoothingAlpha: CGFloat = 0.35

    var body: some View {
        Canvas { context, size in
            let count = min(barCount, displayLevels.count)
            guard count > 0 else { return }

            let totalSpacing = size.width
            let barWidth = totalSpacing / CGFloat(count * 2 - 1)
            let maxHeight = size.height

            for i in 0..<count {
                let level = displayLevels[i]
                let height = max(barWidth, maxHeight * level)
                let x = CGFloat(i) * barWidth * 2
                let y = (maxHeight - height) / 2

                let rect = CGRect(x: x, y: y, width: barWidth, height: height)
                let capsule = Capsule().path(in: rect)

                let progress = CGFloat(i) / CGFloat(count)
                let color = interpolatedColor(progress: progress)

                context.fill(capsule, with: .color(color.opacity(0.5 + level * 0.5)))

                // Glow effect on loud bars
                if level > 0.3 {
                    let glowInset: CGFloat = -2
                    let glowRect = rect.insetBy(dx: glowInset, dy: glowInset)
                    let glowPath = Capsule().path(in: glowRect)
                    context.fill(glowPath, with: .color(color.opacity(level * 0.2)))
                }
            }
        }
        .animation(.easeOut(duration: 0.05), value: displayLevels)
        .onChange(of: levels) { _, newLevels in
            applySmoothing(newLevels)
        }
        .onAppear {
            smoothedLevels = levels
        }
    }

    private var displayLevels: [CGFloat] {
        smoothedLevels.isEmpty ? levels : smoothedLevels
    }

    private func applySmoothing(_ newLevels: [CGFloat]) {
        if smoothedLevels.count != newLevels.count {
            smoothedLevels = newLevels
            return
        }

        smoothedLevels = zip(smoothedLevels, newLevels).map { old, new in
            old + smoothingAlpha * (new - old)
        }
    }

    private func interpolatedColor(progress: CGFloat) -> Color {
        if progress < 0.5 {
            let t = progress / 0.5
            return blend(PMDesign.brandPrimary, PMDesign.brandSecondary, t: t)
        } else {
            let t = (progress - 0.5) / 0.5
            return blend(PMDesign.brandSecondary, PMDesign.brandTertiary, t: t)
        }
    }

    private func blend(_ c1: Color, _ c2: Color, t: CGFloat) -> Color {
        let r1 = UIColor(c1)
        let r2 = UIColor(c2)

        var h1: CGFloat = 0, s1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var h2: CGFloat = 0, s2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        r1.getHue(&h1, saturation: &s1, brightness: &b1, alpha: &a1)
        r2.getHue(&h2, saturation: &s2, brightness: &b2, alpha: &a2)

        return Color(
            hue: h1 + (h2 - h1) * t,
            saturation: s1 + (s2 - s1) * t,
            brightness: b1 + (b2 - b1) * t
        )
    }
}

#Preview {
    WaveformView(
        levels: (0..<48).map { _ in CGFloat.random(in: 0.1...0.9) }
    )
    .frame(height: 80)
    .padding()
}
