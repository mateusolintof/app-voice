import Foundation

class IntegrationClients {
    // Google Calendar Integration
    func createCalendarEvent(title: String, date: Date, apiKey: String) async throws {
        // Note: Real implementation requires OAuth2, which is complex for a snippet.
        // We will use a simplified REST call assuming a valid Access Token is passed as apiKey for this demo.
        // In a real app, use GTMAppAuth.
        
        let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let dateFormatter = ISO8601DateFormatter()
        let startString = dateFormatter.string(from: date)
        let endString = dateFormatter.string(from: date.addingTimeInterval(3600)) // 1 hour duration
        
        let body: [String: Any] = [
            "summary": title,
            "start": ["dateTime": startString],
            "end": ["dateTime": endString]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    // Linear Integration
    func createLinearIssue(title: String, description: String, apiKey: String) async throws {
        let url = URL(string: "https://api.linear.app/graphql")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let query = """
        mutation IssueCreate($title: String!, $description: String!) {
          issueCreate(input: { title: $title, description: $description, teamId: "YOUR_TEAM_ID" }) {
            success
            issue {
              id
              title
            }
          }
        }
        """
        
        let body: [String: Any] = [
            "query": query,
            "variables": [
                "title": title,
                "description": description
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
