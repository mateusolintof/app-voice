import Foundation

struct Message: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    
    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

struct AppConfig: Codable {
    var openAIKey: String = ""
    var googleCalendarKey: String = ""
    var linearKey: String = ""
    var systemPrompt: String = "Você é um assistente pessoal eficiente e direto. Responda sempre em Português do Brasil. Seja conciso."
}
