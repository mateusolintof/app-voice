import Foundation
import SwiftUI

import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
class ChatViewModel {
    var messages: [Message] = []
    var isRecording = false
    var isProcessing = false
    var errorMessage: String?
    
    // Dependencies
    private let audioRecorder = AudioRecorder()
    private let openAIClient = OpenAIClient()
    
    // Configuration (In a real app, this should be stored securely)
    @ObservationIgnored @AppStorage("openAIKey") private var openAIKey = ""
    
    init() {
        // Add initial system message or welcome
        messages.append(Message(role: .assistant, content: "Hello! I'm your PocketMind. How can I help you today?"))
        
        // Observe audio recorder manually or via tracking if needed. 
        // With @Observable, we might need to handle the binding or updates differently if AudioRecorder is also @Observable.
        // However, since we are inside a class, we don't get auto-updates from another @Observable class unless we observe it in a View.
        // For simplicity in this ViewModel, we will sync state manually or expose the recorder.
        // But to keep it simple and working:
    }
    
    // Helper to sync recording state (since we can't easily use .assign with @Observable without Combine)
    func checkRecordingStatus() {
        self.isRecording = audioRecorder.isRecording
    }
    
    func toggleRecording() {
        if audioRecorder.isRecording {
            audioRecorder.stopRecording()
            self.isRecording = false // Sync state
            processRecording()
        } else {
            audioRecorder.startRecording()
            self.isRecording = true // Sync state
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
