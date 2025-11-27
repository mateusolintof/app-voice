import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var inputText = ""
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack {
                // Chat History
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastId = viewModel.messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Input Area
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $inputText)
                        .padding(12)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(20)
                        .foregroundColor(.primary)
                        .disabled(viewModel.isRecording || viewModel.isProcessing)
                    
                    if inputText.isEmpty {
                        Button(action: {
                            withAnimation {
                                viewModel.toggleRecording()
                            }
                        }) {
                            Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .resizable()
                                .frame(width: 44, height: 44)
                                .foregroundColor(viewModel.isRecording ? .red : .blue)
                                .shadow(color: viewModel.isRecording ? .red.opacity(0.5) : .blue.opacity(0.3), radius: 10)
                        }
                        .disabled(viewModel.isProcessing)
                    } else {
                        Button(action: {
                            viewModel.sendMessage(inputText)
                            inputText = ""
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .resizable()
                                .frame(width: 44, height: 44)
                                .foregroundColor(.blue)
                                .shadow(color: .blue.opacity(0.3), radius: 10)
                        }
                        .disabled(viewModel.isProcessing)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
        .navigationTitle("PocketMind")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .overlay {
            if viewModel.isProcessing {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .bottom) {
            if message.role == .user {
                Spacer()
                Text(message.content)
                    .padding(14)
                    .background(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .foregroundColor(.white)
                    .cornerRadius(20, corners: [.topLeft, .topRight, .bottomLeft])
                    .frame(maxWidth: 280, alignment: .trailing)
                    .shadow(color: .blue.opacity(0.2), radius: 5, x: 0, y: 2)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .padding(14)
                        .background(Color(UIColor.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(20, corners: [.topLeft, .topRight, .bottomRight])
                        .frame(maxWidth: 280, alignment: .leading)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Context Menu for Actions
                    HStack {
                        Button("Summarize") {
                            // Action would be handled by parent/viewModel
                        }
                        .font(.caption2)
                        .foregroundColor(.gray)
                        
                        Button("Improve") {
                            // Action
                        }
                        .font(.caption2)
                        .foregroundColor(.gray)
                    }
                    .padding(.leading, 8)
                }
                Spacer()
            }
        }
        .id(message.id)
    }
}

// Helper for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
