import Foundation

struct Note: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var content: String
    var audioURL: URL?
    let createdAt: Date
    var tags: [String]
    
    init(id: UUID = UUID(), title: String, content: String, audioURL: URL? = nil, createdAt: Date = Date(), tags: [String] = []) {
        self.id = id
        self.title = title
        self.content = content
        self.audioURL = audioURL
        self.createdAt = createdAt
        self.tags = tags
    }
}
