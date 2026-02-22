import Foundation
import AVFoundation
import Observation

@Observable
final class AudioRecorder: NSObject {
    var audioRecorder: AVAudioRecorder?
    var isRecording = false
    var recordingURL: URL?
    var audioLevels: [CGFloat] = Array(repeating: 0, count: 40)

    private var meteringTimer: Timer?
    private let barCount = 40

    override init() {
        super.init()
        setupAudioSessionIfNeeded()
    }

    private func setupAudioSessionIfNeeded() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        #endif
    }

    func startRecording() {
        let fileName = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: fileName, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isRecording = true
            recordingURL = nil
            startMetering()
        } catch {
            print("Could not start recording: \(error)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        recordingURL = audioRecorder?.url
        stopMetering()
        audioLevels = Array(repeating: 0, count: barCount)
    }

    func persistAudio() -> String? {
        guard let sourceURL = recordingURL else { return nil }

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let audioDir = docs.appendingPathComponent("JournalAudio", isDirectory: true)

        if !FileManager.default.fileExists(atPath: audioDir.path) {
            try? FileManager.default.createDirectory(at: audioDir, withIntermediateDirectories: true)
        }

        let fileName = sourceURL.lastPathComponent
        let destURL = audioDir.appendingPathComponent(fileName)

        do {
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            return "JournalAudio/\(fileName)"
        } catch {
            print("Failed to persist audio: \(error)")
            return nil
        }
    }

    // MARK: - Metering

    private func startMetering() {
        meteringTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.updateLevels()
        }
    }

    private func stopMetering() {
        meteringTimer?.invalidate()
        meteringTimer = nil
    }

    private func updateLevels() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.updateMeters()

        let power = recorder.averagePower(forChannel: 0)
        let normalized = normalizedLevel(from: power)

        var newLevels = audioLevels
        newLevels.removeFirst()
        newLevels.append(normalized)
        audioLevels = newLevels
    }

    private func normalizedLevel(from power: Float) -> CGFloat {
        let minDb: Float = -60
        let clampedPower = max(power, minDb)
        let normalized = (clampedPower - minDb) / (0 - minDb)
        return CGFloat(normalized)
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
        }
    }
}
