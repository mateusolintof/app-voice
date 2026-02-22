import Foundation

final class OpenAIClient: ObservableObject {
    private let session = URLSession.shared
    private let baseURL = "https://api.openai.com/v1"

    func transcribeAudio(fileURL: URL, apiKey: String) async throws -> String {
        var request = URLRequest(url: URL(string: "\(baseURL)/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = try createMultipartBody(fileURL: fileURL, boundary: boundary)

        let (responseData, response) = try await session.data(for: request)
        try validateHTTP(response: response, data: responseData)

        let result = try JSONDecoder().decode(TranscriptionResponse.self, from: responseData)
        return result.text
    }

    func sendMessage(messages: [Message], apiKey: String, model: String = "gpt-4o") async throws -> String {
        let bodyMessages = messages.map { ["role": $0.role.rawValue, "content": $0.content] }

        let body: [String: Any] = [
            "model": model,
            "messages": bodyMessages
        ]

        let data = try await performJSONRequest(path: "/chat/completions", body: body, apiKey: apiKey)
        let result = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        return result.choices.first?.message.content ?? ""
    }

    func sendStructuredMessage(messages: [Message], apiKey: String, model: String = "gpt-4o") async throws -> String {
        let bodyMessages = messages.map { ["role": $0.role.rawValue, "content": $0.content] }

        let body: [String: Any] = [
            "model": model,
            "messages": bodyMessages,
            "response_format": ["type": "json_object"],
            "temperature": 0.4
        ]

        let data = try await performJSONRequest(path: "/chat/completions", body: body, apiKey: apiKey)
        let result = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        return result.choices.first?.message.content ?? "{}"
    }

    private func performJSONRequest(path: String, body: [String: Any], apiKey: String) async throws -> Data {
        var request = URLRequest(url: URL(string: "\(baseURL)\(path)")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (responseData, response) = try await session.data(for: request)
        try validateHTTP(response: response, data: responseData)
        return responseData
    }

    private func validateHTTP(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "unknown_error"
            throw NSError(
                domain: "OpenAIClient",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        }
    }

    private func createMultipartBody(fileURL: URL, boundary: String) throws -> Data {
        var data = Data()
        let fileData = try Data(contentsOf: fileURL)

        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n".data(using: .utf8)!)

        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("whisper-1\r\n".data(using: .utf8)!)

        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return data
    }
}

struct TranscriptionResponse: Codable {
    let text: String
}

struct ChatCompletionResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: APIMessage
    }

    struct APIMessage: Codable {
        let content: String
    }
}
