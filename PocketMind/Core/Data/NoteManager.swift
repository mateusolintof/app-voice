import Foundation

@Observable
class NoteManager {
    static let shared = NoteManager()
    
    var notes: [Note] = []
    
    private let fileName = "notes.json"
    
    private init() {
        loadNotes()
    }
    
    // MARK: - CRUD Operations
    
    func addNote(title: String, content: String, audioURL: URL?) {
        let newNote = Note(title: title, content: content, audioURL: audioURL)
        notes.insert(newNote, at: 0) // Add to top
        saveNotes()
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
            saveNotes()
        }
    }
    
    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        // Optionally delete audio file here if needed
        saveNotes()
    }
    
    // MARK: - Persistence
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func saveNotes() {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            let data = try JSONEncoder().encode(notes)
            try data.write(to: url)
        } catch {
            print("Failed to save notes: \(error.localizedDescription)")
        }
    }
    
    private func loadNotes() {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            let data = try Data(contentsOf: url)
            notes = try JSONDecoder().decode([Note].self, from: data)
        } catch {
            print("Failed to load notes (might be first run): \(error.localizedDescription)")
            notes = []
        }
    }
}
