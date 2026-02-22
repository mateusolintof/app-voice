import Foundation
import SwiftData

struct IntegrationPayload: Codable {
    var contract: CommitmentContract
    var createdAt: Date
}

struct IntegrationSyncService {
    private let clients = IntegrationClients()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func sync(contract: CommitmentContract, googleCalendarKey: String, linearKey: String, modelContext: ModelContext) async {
        var hasFailure = false
        var lastError = ""

        if !googleCalendarKey.isEmpty {
            do {
                try await clients.createCalendarEvent(
                    title: contract.statement,
                    date: contract.dueAt,
                    apiKey: googleCalendarKey
                )
            } catch {
                hasFailure = true
                lastError = "calendar: \(error.localizedDescription)"
            }
        }

        if !linearKey.isEmpty {
            do {
                try await clients.createLinearIssue(
                    title: contract.statement,
                    description: "Ação: \(contract.nextAction)\nPrazo: \(contract.dueAt.formatted())",
                    apiKey: linearKey
                )
            } catch {
                hasFailure = true
                lastError = lastError.isEmpty ? "linear: \(error.localizedDescription)" : "\(lastError) | linear: \(error.localizedDescription)"
            }
        }

        if hasFailure {
            let payload = IntegrationPayload(contract: contract, createdAt: .now)
            if let data = try? encoder.encode(payload), let json = String(data: data, encoding: .utf8) {
                TherapyRepository.enqueueIntegration(kind: "contract_sync", payload: json, in: modelContext)
                TherapyRepository.logMetric(name: "integration_sync_failed", value: 1, context: lastError, in: modelContext)
            }
        } else {
            TherapyRepository.logMetric(name: "integration_sync_success", value: 1, context: contract.id.uuidString, in: modelContext)
        }
    }

    func retryQueued(googleCalendarKey: String, linearKey: String, modelContext: ModelContext) async {
        let items = TherapyRepository.queuedIntegrations(in: modelContext)

        for item in items {
            guard item.kind == "contract_sync",
                  let data = item.payload.data(using: .utf8),
                  let payload = try? decoder.decode(IntegrationPayload.self, from: data)
            else {
                TherapyRepository.removeQueueItem(item, in: modelContext)
                continue
            }

            do {
                if !googleCalendarKey.isEmpty {
                    try await clients.createCalendarEvent(
                        title: payload.contract.statement,
                        date: payload.contract.dueAt,
                        apiKey: googleCalendarKey
                    )
                }

                if !linearKey.isEmpty {
                    try await clients.createLinearIssue(
                        title: payload.contract.statement,
                        description: "Ação: \(payload.contract.nextAction)",
                        apiKey: linearKey
                    )
                }

                TherapyRepository.removeQueueItem(item, in: modelContext)
                TherapyRepository.logMetric(name: "integration_retry_success", value: Double(item.retries), context: item.id.uuidString, in: modelContext)
            } catch {
                TherapyRepository.registerRetry(for: item, error: error.localizedDescription, in: modelContext)
            }
        }
    }
}
