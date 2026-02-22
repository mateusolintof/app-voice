import SwiftUI
import SwiftData

@main
struct PocketMindApp: App {
    private let container: ModelContainer = {
        let schema = Schema([
            TherapyProfileEntity.self,
            CommitmentEntity.self,
            TherapySessionEntity.self,
            DailyReviewEntity.self,
            MetricEventEntity.self,
            JournalEntryEntity.self
        ])

        let configuration = ModelConfiguration("PocketMindTherapy", schema: schema)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
