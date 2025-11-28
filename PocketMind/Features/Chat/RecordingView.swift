import SwiftUI

struct RecordingView: View {
    @State private var viewModel = ChatViewModel()
    @State private var showAssistant = false
    @FocusState private var isFocused: Bool
    @Binding var showMenu: Bool // To toggle menu from here
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Background
                PremiumTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main Content Area
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            if viewModel.transcribedText.isEmpty && !viewModel.isRecording {
                                EmptyStateView()
                                    .padding(.top, 60)
                            } else {
                                // Text Editor Area
                                TextEditor(text: $viewModel.transcribedText)
                                    .font(.body)
                                    .focused($isFocused)
                                    .frame(minHeight: 300)
                                    .scrollContentBackground(.hidden)
                                    .padding()
                                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding()
                                    .shadow(color: .black.opacity(0.05), radius: 5)
                            }
                        }
                    }
                    .onTapGesture {
                        isFocused = false
                    }
                    
                    // Bottom Control Bar
                    VStack(spacing: 16) {
                        // Assistant Button (Only visible if there is text)
                        if !viewModel.transcribedText.isEmpty {
                            Button(action: { showAssistant = true }) {
                                Label("Abrir Assistente", systemImage: "sparkles")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(PremiumTheme.mainGradient)
                                    .clipShape(Capsule())
                                    .shadow(color: PremiumTheme.gradientStart.opacity(0.5), radius: 8, x: 0, y: 4)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Recording Button Area
                        ZStack {
                            // Recording Indicator
                            if viewModel.isRecording {
                                Circle()
                                    .fill(Color.red.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                    .scaleEffect(1.2)
                                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: viewModel.isRecording)
                            }
                            
                            Button(action: {
                                withAnimation {
                                    viewModel.toggleRecording()
                                }
                            }) {
                                Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.white)
                                    .frame(width: 72, height: 72)
                                    .background(viewModel.isRecording ? Color.red : Color.blue) // Keep simple colors for record button logic
                                    .background(viewModel.isRecording ? nil : PremiumTheme.mainGradient) // Gradient for mic
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 20)
                    .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Nova Gravação")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { withAnimation { showMenu.toggle() } }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .sheet(isPresented: $showAssistant) {
                AssistantToolsView(viewModel: viewModel)
            }
            .overlay {
                if viewModel.isProcessing {
                    ProcessingOverlay()
                }
            }
            .alert("Erro", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}
