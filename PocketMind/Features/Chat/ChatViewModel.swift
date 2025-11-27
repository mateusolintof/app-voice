import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    // Dependencies
    private let audioRecorder = AudioRecorder()
    private let openAIClient = OpenAIClient()
    
    // Configuration (In a real app, this should be stored securely)
    @AppStorage("openAIKey") private var openAIKey = ""
    
    init() {
        // Add initial system message or welcome
        messages.append(Message(role: .assistant, content: "Hello! I'm your PocketMind. How can I help you today?"))
        
        // Observe audio recorder
        audioRecorder.$isRecording.assign(to: &$isRecording)
    }
    
    func toggleRecording() {
        if audioRecorder.isRecording {
            audioRecorder.stopRecording()
            processRecording()
        } else {
            audioRecorder.startRecording()
        }
    }
    
    private func processRecording() {
        guard let url = audioRecorder.recordingURL else { return }
        
        isProcessing = true
        
        Task {
            do {
                guard !openAIKey.isEmpty else {
                    errorMessage = "Please set your OpenAI API Key in Settings."
                    isProcessing = false
                    return
                }
                
                let transcript = try await openAIClient.transcribeAudio(fileURL: url, apiKey: openAIKey)
                
                // Add user message
                let userMessage = Message(role: .user, content: transcript)
                messages.append(userMessage)
                
                // Get AI response
                let response = try await openAIClient.sendMessage(messages: messages, apiKey: openAIKey)
                let aiMessage = Message(role: .assistant, content: response)
                messages.append(aiMessage)
                
            } catch {
                errorMessage = "Error: \(error.localizedDescription)"
            }
            
            isProcessing = false
        }
    }
    
    func sendMessage(_ text: String) {
        let userMessage = Message(role: .user, content: text)
        messages.append(userMessage)
        
        isProcessing = true
        
        Task {
            do {
                guard !openAIKey.isEmpty else {
                    errorMessage = "Please set your OpenAI API Key in Settings."
                    isProcessing = false
                    return
                }
                
                let response = try await openAIClient.sendMessage(messages: messages, apiKey: openAIKey)
                let aiMessage = Message(role: .assistant, content: response)
                messages.append(aiMessage)
            } catch {
                errorMessage = "Error: \(error.localizedDescription)"
            }
            
            isProcessing = false
        }
    }
}
