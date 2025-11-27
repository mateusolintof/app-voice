import SwiftUI

struct MainView: View {
    @State private var viewModel = ChatViewModel()
    @State private var showSettings = false
    @State private var showAssistant = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Background
                Color(uiColor: .systemGroupedBackground)
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
                                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding()
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
                                    .background(
                                        LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .clipShape(Capsule())
                                    .shadow(radius: 4)
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
                                    .background(viewModel.isRecording ? Color.red : Color.blue)
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
            .navigationTitle("PocketMind")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.gray)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
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

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 60))
                .foregroundStyle(.gray.opacity(0.5))
            
            Text("Toque no microfone para começar")
                .font(.headline)
                .foregroundStyle(.gray)
            
            Text("Sua voz será transcrita automaticamente.")
                .font(.caption)
                .foregroundStyle(.gray.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProcessingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Processando...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
