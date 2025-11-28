import SwiftUI

struct NoteDetailView: View {
    let note: Note
    @State private var showAssistant = false
    @State private var viewModel = ChatViewModel() // Reusing ViewModel for actions
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Info
                HStack {
                    Image(systemName: "calendar")
                    Text(note.createdAt.formatted(date: .long, time: .shortened))
                    Spacer()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                
                // Content
                Text(note.content)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                
                // Audio Player Placeholder (Future Implementation)
                if note.audioURL != nil {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                        Text("Reproduzir Áudio Original")
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle(note.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    viewModel.transcribedText = note.content // Load note content into VM
                    showAssistant = true
                }) {
                    Label("Assistente", systemImage: "sparkles")
                }
            }
        }
        .sheet(isPresented: $showAssistant) {
            AssistantToolsView(viewModel: viewModel)
        }
    }
}
