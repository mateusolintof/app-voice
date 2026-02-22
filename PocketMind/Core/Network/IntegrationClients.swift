import Foundation

final class IntegrationClients {
    func createCalendarEvent(title: String, date: Date, apiKey: String) async throws {
        let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let dateFormatter = ISO8601DateFormatter()
        let startString = dateFormatter.string(from: date)
        let endString = dateFormatter.string(from: date.addingTimeInterval(3600))

        let body: [String: Any] = [
            "summary": title,
            "start": ["dateTime": startString],
            "end": ["dateTime": endString]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode)
        else {
            throw URLError(.badServerResponse)
        }
    }

    func createLinearIssue(title: String, description: String, apiKey: String) async throws {
        let teamId = try await fetchFirstLinearTeamId(apiKey: apiKey)

        let mutation = """
        mutation IssueCreate($title: String!, $description: String!, $teamId: String!) {
          issueCreate(input: { title: $title, description: $description, teamId: $teamId }) {
            success
          }
        }
        """

        let body: [String: Any] = [
            "query": mutation,
            "variables": [
                "title": title,
                "description": description,
                "teamId": teamId
            ]
        ]

        _ = try await executeLinearRequest(body: body, apiKey: apiKey)
    }

    private func fetchFirstLinearTeamId(apiKey: String) async throws -> String {
        let query = """
        query Teams {
          teams(first: 1) {
            nodes {
              id
            }
          }
        }
        """

        let body: [String: Any] = ["query": query]
        let data = try await executeLinearRequest(body: body, apiKey: apiKey)

        let decoded = try JSONDecoder().decode(LinearTeamLookupResponse.self, from: data)
        guard let teamId = decoded.data.teams.nodes.first?.id else {
            throw URLError(.resourceUnavailable)
        }

        return teamId
    }

    private func executeLinearRequest(body: [String: Any], apiKey: String) async throws -> Data {
        let url = URL(string: "https://api.linear.app/graphql")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode)
        else {
            throw URLError(.badServerResponse)
        }

        return data
    }
}

private struct LinearTeamLookupResponse: Decodable {
    let data: LinearData

    struct LinearData: Decodable {
        let teams: Teams
    }

    struct Teams: Decodable {
        let nodes: [TeamNode]
    }

    struct TeamNode: Decodable {
        let id: String
    }
}
