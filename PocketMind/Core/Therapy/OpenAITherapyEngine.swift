import Foundation

enum TherapyEngineError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case decodingFailed(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Chave OpenAI nao configurada. Va em Perfil para adicionar sua chave."
        case .invalidResponse:
            return "Resposta invalida do servidor. Tente novamente."
        case .decodingFailed(let detail):
            return "Falha ao processar resposta da IA: \(detail)"
        case .networkError(let detail):
            return "Erro de rede: \(detail)"
        }
    }
}

struct OpenAITherapyEngine: TherapyEngine {
    private let client = OpenAIClient()
    private let decoder = JSONDecoder()

    func runTurn(input: String, context: TherapyContext) async throws -> TherapyTurnEnvelope {
        if let critical = checkCriticalInput(input: input) {
            return critical
        }

        let apiKey = UserDefaults.standard.string(forKey: "openAIKey") ?? ""
        guard !apiKey.isEmpty else {
            throw TherapyEngineError.missingAPIKey
        }

        let systemPrompt = buildSystemPrompt(profile: context.profile)
        let userPrompt = buildTurnPrompt(input: input, context: context)

        let messages = [
            Message(role: .system, content: systemPrompt),
            Message(role: .user, content: userPrompt)
        ]

        let raw: String
        do {
            raw = try await client.sendStructuredMessage(messages: messages, apiKey: apiKey, model: "gpt-4o")
        } catch {
            throw TherapyEngineError.networkError(error.localizedDescription)
        }

        guard let data = raw.data(using: .utf8) else {
            throw TherapyEngineError.invalidResponse
        }

        do {
            return try decoder.decode(TherapyTurnEnvelope.self, from: data)
        } catch {
            throw TherapyEngineError.decodingFailed(error.localizedDescription)
        }
    }

    func runRitual(slot: RitualSlot, context: TherapyContext) async throws -> RitualOutput {
        let slotPrompt: String

        switch slot {
        case .morning:
            slotPrompt = "Ritual da manhã: defina missão, obstáculo principal e compromisso executável."
        case .midday:
            slotPrompt = "Ritual do meio do dia: confrontar autoengano, recalibrar e escolher próximo passo curto."
        case .evening:
            slotPrompt = "Ritual da noite: revisão objetiva, aprendizado e ajuste para amanhã."
        }

        let envelope = try await runTurn(input: slotPrompt, context: context)

        return RitualOutput(
            slot: slot,
            summary: envelope.rawReality,
            mission: context.currentMission.isEmpty ? envelope.meaningAnchor : context.currentMission,
            contract: envelope.contract,
            accountabilityPrompt: envelope.followupQuestion
        )
    }

    func runRecovery(context: TherapyContext) async throws -> RecoveryOutput {
        let prompt = "Executar protocolo de recuperação após desvio: reconhecer fricção, cortar narrativa e propor retomada em até 90 segundos."
        let envelope = try await runTurn(input: prompt, context: context)

        return RecoveryOutput(
            summary: envelope.reframing,
            frictionDetected: envelope.diagnosis.distortionTags,
            resetAction: envelope.contract.nextAction,
            contract: envelope.contract
        )
    }

    // MARK: - System Prompt

    private func buildSystemPrompt(profile: TherapyProfile) -> String {
        let styleIntensity = max(1, min(5, profile.confrontationLevel))
        let methodDescription = buildMethodDescription(modes: profile.defaultModes)

        return """
        Você é um terapeuta cognitivo pessoal para uso individual, direto e confrontador em Português do Brasil.
        Método: \(methodDescription).
        Regras:
        1) Faça diagnóstico cognitivo claro, sem rodeios.
        2) Identifique distorções cognitivas e reestruture pensamentos.
        3) Separe o que está sob controle do que não está (dicotomia do controle).
        4) Vincule ação a sentido/propósito pessoal.
        5) Sempre defina ação de até 15 minutos.
        6) Gere contrato objetivo com horário.
        7) Tom de confronto nível \(styleIntensity)/5: firme, sem agressividade.
        8) Responda SOMENTE JSON válido, sem markdown, sem blocos de código.
        Estrutura JSON obrigatória (siga exatamente):
        {
          "rawReality": "frase sobre a realidade crua",
          "diagnosis": {
            "distortionTags": ["nome_da_distorcao"],
            "controlSplit": {
              "underControl": ["item que o usuario controla"],
              "notUnderControl": ["item fora do controle"]
            },
            "avoidanceScore": 0.5
          },
          "reframing": "reenquadramento orientado a responsabilidade",
          "meaningAnchor": "ancora de sentido pessoal",
          "contract": {
            "id": "\(UUID().uuidString)",
            "statement": "compromisso claro",
            "nextAction": "acao concreta em ate 15 min",
            "durationMinutes": 15,
            "dueAt": "\(ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600)))",
            "accountabilityPrompt": "pergunta de cobranca",
            "status": "planned"
          },
          "followupQuestion": "pergunta para proximo check-in"
        }
        IMPORTANTE: O campo "id" deve ser um UUID válido (ex: "550e8400-e29b-41d4-a716-446655440000"). O campo "dueAt" deve ser ISO8601 (ex: "2026-02-22T20:00:00Z").
        """
    }

    private func buildMethodDescription(modes: [InterventionMode]) -> String {
        if modes.contains(.blended) || modes.count >= 3 {
            return "CBT + Estoicismo + Logoterapia"
        }

        var parts: [String] = []
        if modes.contains(.cbt) {
            parts.append("Terapia Cognitivo-Comportamental")
        }
        if modes.contains(.stoic) {
            parts.append("Estoicismo")
        }
        if modes.contains(.logotherapy) {
            parts.append("Logoterapia")
        }

        return parts.isEmpty ? "CBT + Estoicismo + Logoterapia" : parts.joined(separator: " + ")
    }

    private func buildTurnPrompt(input: String, context: TherapyContext) -> String {
        let pending = context.pendingCommitments.map {
            "- \($0.statement) | ação: \($0.nextAction) | status: \($0.status.rawValue)"
        }.joined(separator: "\n")

        let friction = context.recentFrictionNotes.joined(separator: " | ")

        return """
        Entrada verbal do usuário:
        \(input)

        Contexto:
        - Ritual atual: \(context.activeSlot.rawValue)
        - Missão atual: \(context.currentMission)
        - Compromissos pendentes:
        \(pending.isEmpty ? "(nenhum)" : pending)
        - Fricções recentes: \(friction.isEmpty ? "(nenhuma)" : friction)

        Saída esperada:
        - Fato cru da realidade
        - Distorções cognitivas dominantes
        - Dicotomia do controle
        - Reenquadramento orientado a responsabilidade
        - Contrato com próxima ação <= 15min e prazo em ISO8601
        - Pergunta de cobrança para próximo check-in
        """
    }

    // MARK: - Critical Safety Check

    private func checkCriticalInput(input: String) -> TherapyTurnEnvelope? {
        let criticalTerms = [
            "suicidio", "suicídio", "me matar", "tirar minha vida", "não quero viver",
            "auto mutilação", "automutilação", "self harm"
        ]

        let normalized = input.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

        guard criticalTerms.contains(where: { normalized.contains($0) }) else {
            return nil
        }

        let dueAt = Date().addingTimeInterval(5 * 60)

        return TherapyTurnEnvelope(
            rawReality: "Você descreveu um cenário de risco agudo e isso exige ajuda humana imediata.",
            diagnosis: CognitiveDiagnosis(
                distortionTags: ["risco_agudo"],
                controlSplit: ControlSplit(
                    underControl: ["Pedir ajuda agora", "Acionar contato de confiança"],
                    notUnderControl: ["Resolver tudo sozinho neste momento"]
                ),
                avoidanceScore: 0.0
            ),
            reframing: "A ação mais corajosa agora é buscar suporte imediato.",
            meaningAnchor: "Sua vida tem valor intrínseco; priorize proteção imediata.",
            contract: CommitmentContract(
                statement: "Vou acionar ajuda humana imediatamente.",
                nextAction: "Ligue 188 (CVV, Brasil) agora ou contate um serviço de emergência local.",
                durationMinutes: 5,
                dueAt: dueAt,
                accountabilityPrompt: "Você consegue confirmar que acionou ajuda agora?",
                status: .planned
            ),
            followupQuestion: "Quem é a primeira pessoa de confiança que você pode chamar neste minuto?"
        )
    }
}
