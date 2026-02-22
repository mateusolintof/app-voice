import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class ReviewViewModel {
    var winsInput: String = ""
    var frictionsInput: String = ""
    var lesson: String = ""
    var adjustment: String = ""
    var consistencyScore: Double = 3

    var statusMessage: String = ""

    func saveReview(modelContext: ModelContext) {
        let wins = splitList(winsInput)
        let frictions = splitList(frictionsInput)

        TherapyRepository.saveReview(
            date: Date(),
            wins: wins,
            frictions: frictions,
            lesson: lesson,
            adjustment: adjustment,
            consistencyScore: Int(consistencyScore),
            in: modelContext
        )

        TherapyRepository.logMetric(
            name: "daily_review_saved",
            value: consistencyScore,
            context: Date.now.formatted(date: .abbreviated, time: .omitted),
            in: modelContext
        )

        statusMessage = "Revisão salva."
    }

    func completionRate(for commitments: [CommitmentEntity]) -> Double {
        guard !commitments.isEmpty else { return 0 }

        let done = commitments.filter { CommitmentStatus(rawValue: $0.statusRaw) == .completed }.count
        return Double(done) / Double(commitments.count)
    }

    private func splitList(_ value: String) -> [String] {
        value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
