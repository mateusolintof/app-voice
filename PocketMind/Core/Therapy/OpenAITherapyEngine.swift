import Foundation

enum TherapyEngineError: Error {
    case missingAPIKey
    case invalidResponse
}

struct OpenAITherapyEngine: TherapyEngine {
    private let client = OpenAIClient()
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func runTurn(input: String, context: TherapyContext) async throws -> TherapyTurnEnvelope {
        if let critical = criticalResponseIfNeeded(input: input) {
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

        let raw = try await client.sendStructuredMessage(messages: messages, apiKey: apiKey, model: "gpt-4o")

        guard let data = raw.data(using: .utf8) else {
            throw TherapyEngineError.invalidResponse
        }

        do {
            return try decoder.decode(TherapyTurnEnvelope.self, from: data)
        } catch {
            return fallbackEnvelope(from: input, context: context)
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

    private func buildSystemPrompt(profile: TherapyProfile) -> String {
        let styleIntensity = max(1, min(5, profile.confrontationLevel))

        return """
        Você é um terapeuta cognitivo pessoal para uso individual, direto e confrontador em Português do Brasil.
        Método obrigatório: CBT + Estoicismo + Logoterapia.
        Regras:
        1) Faça diagnóstico cognitivo claro, sem rodeios.
        2) Use dicotomia do controle explicitamente.
        3) Vincule ação a sentido/proposito pessoal.
        4) Sempre defina ação de até 15 minutos.
        5) Gere contrato objetivo com horário.
        6) Tom de confronto nível \(styleIntensity)/5: firme, sem agressividade.
        7) Responda SOMENTE JSON válido, sem markdown.
        Estrutura JSON:
        {
          "rawReality": "string",
          "diagnosis": {
            "distortionTags": ["string"],
            "controlSplit": {
              "underControl": ["string"],
              "notUnderControl": ["string"]
            },
            "avoidanceScore": 0.0
          },
          "reframing": "string",
          "meaningAnchor": "string",
          "contract": {
            "id": "UUID",
            "statement": "string",
            "nextAction": "string",
            "durationMinutes": 15,
            "dueAt": "ISO8601",
            "accountabilityPrompt": "string",
            "status": "planned"
          },
          "followupQuestion": "string"
        }
        """
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

    private func fallbackEnvelope(from input: String, context: TherapyContext) -> TherapyTurnEnvelope {
        let dueAt = Date().addingTimeInterval(15 * 60)

        return TherapyTurnEnvelope(
            rawReality: "Você está carregando informações demais sem transformar em execução objetiva.",
            diagnosis: CognitiveDiagnosis(
                distortionTags: ["sobrecarga", "ambiguidade"],
                controlSplit: ControlSplit(
                    underControl: ["Definir o próximo passo", "Executar 15 minutos"],
                    notUnderControl: ["Resultado final imediato"]
                ),
                avoidanceScore: 0.42
            ),
            reframing: "Sem execução curta, não existe clareza. Clareza vem da ação, não da ruminação.",
            meaningAnchor: context.currentMission.isEmpty ? "Seu propósito hoje é recuperar agência sobre o próprio dia." : context.currentMission,
            contract: CommitmentContract(
                statement: "Vou executar um bloco curto agora, sem negociar comigo mesmo.",
                nextAction: "Escolher a tarefa mais crítica e trabalhar 15 minutos sem distração.",
                durationMinutes: 15,
                dueAt: dueAt,
                accountabilityPrompt: "Você começou esse bloco agora?",
                status: .planned
            ),
            followupQuestion: "Qual evidência concreta você terá em 15 minutos de que avançou?"
        )
    }

    private func criticalResponseIfNeeded(input: String) -> TherapyTurnEnvelope? {
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
