import Foundation
import SwiftUI

import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
class ChatViewModel {
    // State
    var transcribedText: String = ""
    var messages: [Message] = [] // Mantido para histórico de ações, se necessário
    var isRecording = false
    var isProcessing = false
    var errorMessage: String?
    var showTools = false // Controla a visibilidade do menu de ferramentas
    
    // Dependencies
    private let audioRecorder = AudioRecorder()
    private let openAIClient = OpenAIClient()
    
    // Configuration
    @ObservationIgnored @AppStorage("openAIKey") private var openAIKey = ""
    
    init() {
        // Estado inicial limpo
    }
    
    // MARK: - Recording Logic
    
    func toggleRecording() {
        if audioRecorder.isRecording {
            audioRecorder.stopRecording()
            self.isRecording = false
            processRecording()
        } else {
            audioRecorder.startRecording()
            self.isRecording = true
            self.transcribedText = "" // Limpa texto anterior ao iniciar nova gravação
            self.errorMessage = nil
        }
    }
    
    private func processRecording() {
        guard let url = audioRecorder.recordingURL else { return }
        
        isProcessing = true
        
        Task {
            do {
                guard !openAIKey.isEmpty else {
                    errorMessage = "Por favor, configure sua chave da OpenAI nas Configurações."
                    isProcessing = false
                    return
                }
                
                // 1. Transcribe only
                let transcript = try await openAIClient.transcribeAudio(fileURL: url, apiKey: openAIKey)
                
                await MainActor.run {
                    self.transcribedText = transcript
                    self.showTools = true // Mostra as ferramentas após transcrever
                    
                    // Auto-save Note
                    let title = "Nota \(Date().formatted(date: .numeric, time: .shortened))"
                    NoteManager.shared.addNote(title: title, content: transcript, audioURL: url)
                }
                
            } catch {
                errorMessage = "Erro na transcrição: \(error.localizedDescription)"
            }
            
            isProcessing = false
        }
    }
    
    // MARK: - AI Actions
    
    func performAction(_ action: AIAction) {
        Task {
            let result = await performActionReturningResult(action)
            await MainActor.run {
                self.transcribedText = result
            }
        }
    }
    
    func performActionReturningResult(_ action: AIAction) async -> String {
        guard !transcribedText.isEmpty else { return "" }
        guard !openAIKey.isEmpty else {
            await MainActor.run { errorMessage = "Configure sua chave da OpenAI." }
            return ""
        }
        
        await MainActor.run { isProcessing = true }
        
        do {
            let prompt = action.prompt(for: transcribedText)
            
            // Adiciona contexto do sistema para garantir PT-BR
            let systemMessage = Message(role: .system, content: "Você é um assistente pessoal eficiente. Responda sempre em Português do Brasil.")
            let userMessage = Message(role: .user, content: prompt)
            
            let response = try await openAIClient.sendMessage(messages: [systemMessage, userMessage], apiKey: openAIKey)
            
            await MainActor.run { isProcessing = false }
            return response
            
        } catch {
            await MainActor.run {
                errorMessage = "Erro na ação: \(error.localizedDescription)"
                isProcessing = false
            }
            return ""
        }
    }
}

enum AIAction {
    case summarize
    case improve
    case generatePrompt
    case createTask
    
    func prompt(for text: String) -> String {
        switch self {
        case .summarize:
            return "Resuma o seguinte texto em tópicos concisos:\n\n\(text)"
        case .improve:
            return "Reescreva o seguinte texto para torná-lo mais profissional, claro e corrigir erros gramaticais:\n\n\(text)"
        case .generatePrompt:
            return "Com base no texto abaixo, crie um prompt estruturado e detalhado para uma IA generativa:\n\n\(text)"
        case .createTask:
            return "Extraia as tarefas acionáveis do seguinte texto e formate-as como uma lista de verificação (checklist):\n\n\(text)"
        }
    }
}
