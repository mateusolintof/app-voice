import SwiftUI

struct WaveformView: View {
    let levels: [CGFloat]
    var barCount: Int = 40
    var accentColor: Color = PMDesign.accent

    var body: some View {
        Canvas { context, size in
            let barWidth = size.width / CGFloat(barCount * 2 - 1)
            let maxHeight = size.height

            for i in 0..<barCount {
                let level = i < levels.count ? levels[i] : 0
                let height = max(barWidth, maxHeight * level)
                let x = CGFloat(i) * barWidth * 2
                let y = (maxHeight - height) / 2

                let rect = CGRect(x: x, y: y, width: barWidth, height: height)
                let capsule = Capsule().path(in: rect)

                let progress = CGFloat(i) / CGFloat(barCount)
                let color = Color(
                    hue: lerp(from: 0.72, to: 0.52, t: progress),
                    saturation: 0.6,
                    brightness: 0.8
                )

                context.fill(capsule, with: .color(color.opacity(0.5 + level * 0.5)))
            }
        }
        .animation(.easeOut(duration: 0.08), value: levels)
    }

    private func lerp(from a: CGFloat, to b: CGFloat, t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }
}

#Preview {
    WaveformView(
        levels: (0..<40).map { _ in CGFloat.random(in: 0.1...0.9) }
    )
    .frame(height: 80)
    .padding()
}
