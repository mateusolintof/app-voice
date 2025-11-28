import SwiftUI

struct NoteDetailView: View {
    @State var note: Note
    @State private var showAssistant = false
    @State private var viewModel = ChatViewModel()
    @State private var isEditing = false
    @State private var editedTitle = ""
    @State private var editedContent = ""
    @FocusState private var isFocused: Bool
    
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
                
                if isEditing {
                    // Edit Mode
                    VStack(spacing: 16) {
                        TextField("Título", text: $editedTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                            .textFieldStyle(.roundedBorder)
                        
                        TextEditor(text: $editedContent)
                            .font(.body)
                            .frame(minHeight: 300)
                            .scrollContentBackground(.hidden)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .focused($isFocused)
                    }
                    .padding(.horizontal)
                } else {
                    // View Mode
                    Text(note.content)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        .textSelection(.enabled)
                }
                
                // Edit / Save Button Area
                Button(action: {
                    if isEditing {
                        saveChanges()
                    } else {
                        startEditing()
                    }
                }) {
                    HStack {
                        Image(systemName: isEditing ? "checkmark" : "pencil")
                        Text(isEditing ? "Salvar Alterações" : "Editar Nota")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isEditing ? Color.green : Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle(isEditing ? "Editando" : note.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !isEditing {
                    Button(action: {
                        viewModel.transcribedText = note.content // Load note content into VM context
                        showAssistant = true
                    }) {
                        Label("Assistente", systemImage: "sparkles")
                    }
                }
            }
        }
        .sheet(isPresented: $showAssistant) {
            AssistantToolsView(viewModel: viewModel) { result in
                if !result.isEmpty {
                    appendAIResult(result)
                }
            }
        }
        .onAppear {
            // Ensure local state matches passed note
            // (In case we navigated back and forth)
        }
    }
    
    private func startEditing() {
        editedTitle = note.title
        editedContent = note.content
        isEditing = true
        isFocused = true
    }
    
    private func saveChanges() {
        note.title = editedTitle
        note.content = editedContent
        NoteManager.shared.updateNote(note)
        isEditing = false
        isFocused = false
    }
    
    private func appendAIResult(_ result: String) {
        // We need to be careful not to duplicate if the user cancelled or didn't run an action.
        // A better way is to pass a closure to AssistantToolsView.
        // But for now, let's assume the VM holds the RESULT.
        
        // Let's format the result
        let newContent = note.content + "\n\n---\n\n" + result
        note.content = newContent
        NoteManager.shared.updateNote(note)
        
        // Reset VM text to avoid re-appending
        viewModel.transcribedText = newContent
    }
}
