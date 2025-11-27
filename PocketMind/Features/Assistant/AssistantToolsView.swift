import SwiftUI

struct AssistantToolsView: View {
    let viewModel: ChatViewModel
    @Environment(\.dismiss) var dismiss
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ToolCard(icon: "doc.text", title: "Resumir", color: .blue) {
                        viewModel.performAction(.summarize)
                        dismiss()
                    }
                    
                    ToolCard(icon: "wand.and.stars", title: "Melhorar", color: .purple) {
                        viewModel.performAction(.improve)
                        dismiss()
                    }
                    
                    ToolCard(icon: "brain.head.profile", title: "Gerar Prompt", color: .orange) {
                        viewModel.performAction(.generatePrompt)
                        dismiss()
                    }
                    
                    ToolCard(icon: "checklist", title: "Criar Tarefa", color: .green) {
                        viewModel.performAction(.createTask)
                        dismiss()
                    }
                }
                .padding()
            }
            .navigationTitle("Assistente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct ToolCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(color)
                    .frame(width: 60, height: 60)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}
