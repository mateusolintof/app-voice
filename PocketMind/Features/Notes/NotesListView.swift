import SwiftUI

struct NotesListView: View {
    @State private var notes: [Note] = []
    @State private var searchText = ""
    
    var filteredNotes: [Note] {
        if searchText.isEmpty {
            return notes
        } else {
            return notes.filter { $0.title.localizedCaseInsensitiveContains(searchText) || $0.content.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                if notes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "note.text")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray.opacity(0.5))
                        Text("Nenhuma nota ainda")
                            .font(.headline)
                            .foregroundStyle(.gray)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredNotes) { note in
                                NavigationLink(destination: NoteDetailView(note: note)) {
                                    NoteCard(note: note)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Minhas Notas")
            .searchable(text: $searchText, prompt: "Buscar notas...")
            .onAppear {
                notes = NoteManager.shared.notes
            }
            .onChange(of: NoteManager.shared.notes) {
                notes = NoteManager.shared.notes
            }
        }
    }
}

struct NoteCard: View {
    let note: Note
    
    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(note.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(note.content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                    
                    Spacer()
                    
                    if note.audioURL != nil {
                        Image(systemName: "mic.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
            }
        }
    }
}
