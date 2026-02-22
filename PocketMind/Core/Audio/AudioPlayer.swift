import Foundation
import AVFoundation
import Observation

@Observable
final class AudioPlayer: NSObject {
    var isPlaying = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0

    private var player: AVAudioPlayer?
    private var progressTimer: Timer?

    func play(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        do {
            if player?.url == url, let existing = player {
                if existing.isPlaying {
                    existing.pause()
                    isPlaying = false
                    stopProgressTimer()
                } else {
                    existing.play()
                    isPlaying = true
                    startProgressTimer()
                }
                return
            }

            player?.stop()
            stopProgressTimer()

            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.prepareToPlay()
            duration = player?.duration ?? 0
            currentTime = 0
            player?.play()
            isPlaying = true
            startProgressTimer()
        } catch {
            print("AudioPlayer error: \(error)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        stopProgressTimer()
    }

    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
    }

    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else { return }
            self.currentTime = player.currentTime
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = 0
        stopProgressTimer()
    }
}
