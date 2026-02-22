import SwiftUI

struct AudioPlayerView: View {
    let audioFilePath: String
    @State private var player = AudioPlayer()

    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(audioFilePath)
    }

    var body: some View {
        GlassCard(cornerRadius: PMDesign.cornerSmall, padding: PMDesign.spacingS) {
            HStack(spacing: 12) {
                Button {
                    player.play(url: fileURL)
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.body)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(PMDesign.brandGradient)
                        .clipShape(Circle())
                }
                .buttonStyle(PressScaleButtonStyle())

                if player.duration > 0 {
                    Slider(
                        value: Binding(
                            get: { player.currentTime },
                            set: { player.seek(to: $0) }
                        ),
                        in: 0...max(player.duration, 0.01)
                    )
                    .tint(PMDesign.brandPrimary)

                    Text(formatTime(player.currentTime))
                        .font(PMDesign.caption2Rounded)
                        .foregroundStyle(PMDesign.textTertiary)
                        .monospacedDigit()
                        .frame(minWidth: 40, alignment: .trailing)
                } else {
                    Spacer()

                    Text("Audio")
                        .font(PMDesign.caption2Rounded)
                        .foregroundStyle(PMDesign.textTertiary)
                }
            }
        }
        .onDisappear {
            player.stop()
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
