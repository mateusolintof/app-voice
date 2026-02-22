import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class TodayViewModel {
    var greeting: String = ""
    var currentSlot: RitualSlot = .morning
    var todayMission: String = ""
    var todayEntryCount: Int = 0
    var hasReview: Bool = false
    var completionRate: Double = 0
    var completedCount: Int = 0
    var totalCount: Int = 0
    var recentEntry: JournalEntryEntity?

    func load(modelContext: ModelContext) {
        let profile = TherapyRepository.currentProfile(in: modelContext)
        updateGreeting()
        updateSlot(profile: profile)
        loadMission(modelContext: modelContext)
        loadJournalStats(modelContext: modelContext)
        loadCommitmentStats(modelContext: modelContext)
        loadReviewStatus(modelContext: modelContext)
    }

    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        let userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        let nameSuffix = userName.isEmpty ? "" : ", \(userName)"

        switch hour {
        case 5..<12:
            greeting = "Bom dia\(nameSuffix)"
        case 12..<18:
            greeting = "Boa tarde\(nameSuffix)"
        default:
            greeting = "Boa noite\(nameSuffix)"
        }
    }

    private func updateSlot(profile: TherapyProfile? = nil) {
        let now = Date()
        let calendar = Calendar.current

        if let profile {
            let morningH = calendar.component(.hour, from: profile.morningWindow.start)
            let morningEnd = calendar.component(.hour, from: profile.morningWindow.end)
            let middayH = calendar.component(.hour, from: profile.middayWindow.start)
            let middayEnd = calendar.component(.hour, from: profile.middayWindow.end)

            let hour = calendar.component(.hour, from: now)
            if hour >= morningH && hour < morningEnd {
                currentSlot = .morning
            } else if hour >= middayH && hour < middayEnd {
                currentSlot = .midday
            } else {
                currentSlot = .evening
            }
        } else {
            let hour = calendar.component(.hour, from: now)
            switch hour {
            case 5..<12: currentSlot = .morning
            case 12..<17: currentSlot = .midday
            default: currentSlot = .evening
            }
        }
    }

    private func loadMission(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<TherapySessionEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        if let session = try? modelContext.fetch(descriptor).first {
            todayMission = session.meaningAnchor
        }
    }

    private func loadJournalStats(modelContext: ModelContext) {
        let entries = JournalRepository.fetchEntries(for: Date(), in: modelContext)
        todayEntryCount = entries.count
        recentEntry = entries.first
    }

    private func loadCommitmentStats(modelContext: ModelContext) {
        let commitments = TherapyRepository.fetchCommitments(for: Date(), in: modelContext)
        totalCount = commitments.count
        completedCount = commitments.filter { CommitmentStatus(rawValue: $0.statusRaw) == .completed }.count
        completionRate = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
    }

    private func loadReviewStatus(modelContext: ModelContext) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? Date()

        let descriptor = FetchDescriptor<DailyReviewEntity>(
            predicate: #Predicate { $0.date >= start && $0.date < end }
        )

        hasReview = (try? modelContext.fetch(descriptor).first) != nil
    }
}
