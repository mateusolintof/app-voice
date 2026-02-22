# PocketMind v3.0 - Roadmap Estrategico de Produto

> Documento gerado a partir de pesquisa competitiva (Woebot, Wysa, Youper, Daylio, Finch, Bearable) e analise profunda do codebase atual. Serve como guia de implementacao para todas as melhorias planejadas.

---

## Analise Competitiva

| App | Forca Principal | Licao para PocketMind |
|-----|----------------|----------------------|
| **Daylio** | 40% retencao Dia-30, Year in Pixels | Mood tracking rapido + visualizacao = retencao |
| **Woebot** | CBT conversacional, RCT Stanford | Check-ins diarios guiados criam habito |
| **Wysa** | 150+ exercicios, FDA Breakthrough | Onboarding guiado e imediato em valor |
| **Youper** | #1 engajamento JAMA, Apple Health | Dados biometricos enriquecem contexto |
| **Finch** | Gamificacao emocional (pet companion) | Motivacao por afeto > por obrigacao |
| **Bearable** | Export p/ terapeutas e psiquiatras | Dados exportaveis = confianca + diferencial |

### Dados de Mercado
- Apps com gamificacao: **48% maior retencao** (estudo 2022)
- Streaks + milestones: **40-60% maior DAU**, reduzem churn 30d em **35%** (Forrester 2024)
- Usuarios com 7+ dias de streak: **2.3x mais propensos** a engajar diariamente
- 92.7% de jovens acham conselhos de IA para saude mental uteis (RAND/JAMA 2025)

---

## Problemas Identificados no App Atual

### Dados Coletados mas Nunca Exibidos
| Dado | Onde e salvo | Onde deveria aparecer |
|------|-------------|---------------------|
| `moodTag` | `JournalEntryEntity` | Nunca preenchido (sempre nil) |
| `MetricEventEntity` | 6 tipos de eventos logados | Nenhuma tela consome |
| `avoidanceScore` | `TherapySessionEntity` | Nunca exibido |
| `underControlRaw/notUnderControlRaw` | `TherapySessionEntity` | Nunca exibido |
| `commitmentId` | `JournalEntryEntity` | Nenhuma UI usa o link |
| Time windows do perfil | `TherapyProfileEntity` | Slot detection usa horas hardcoded |

### Features Quebradas/Incompletas
| Feature | Status |
|---------|--------|
| Toggles de therapy mode | Salvos mas ignorados pelo system prompt |
| Audio playback | Audio gravado e persistido, mas sem player |
| Status "Adiado" | Existe no enum mas e inalcancavel na UI |
| `sendMessage()` em OpenAIClient | Dead code nunca chamado |
| `AppConfig` struct | Nunca instanciada |
| `showResults` em RitualActionCard | Declarado mas nunca lido |
| Onboarding | Inexistente |

---

## Tier 1 - Critico: Corrigir o que Esta Quebrado

### T1.1 Onboarding Guiado
**Problema**: App abre em dashboard vazio. Usuario precisa descobrir sozinho a aba Perfil e entender "chave OpenAI". Taxa de abandono critica.

**Solucao**: Fluxo de 4 telas na primeira abertura:
1. **Boas-vindas**: AnimatedMeshBackground + logo + "Seu coach pessoal com IA"
2. **Nome do usuario**: TextField simples, salvo em `@AppStorage("userName")`
3. **Chave OpenAI**: Reutiliza SecureField do ProfileView + link para platform.openai.com + opcao "Nao tenho agora"
4. **Personalizacao**: Slider de confrontacao + pergunta inicial processada pela IA que gera o primeiro `meaningAnchor`

**Arquivos a criar/modificar**:
- `ContentView.swift` - gate com `@AppStorage("onboardingCompleted")` + `.fullScreenCover`
- `PocketMindApp.swift` - `@AppStorage("userName")`
- Criar `Features/Onboarding/OnboardingFlow.swift`
- Criar `Features/Onboarding/OnboardingViewModel.swift`

---

### T1.2 Selecao de Humor (MoodTag) Funcional
**Problema**: `JournalEntryEntity.moodTag` existe no modelo, e pesquisavel, e exibido na UI de detalhe, mas `VoiceRecordingViewModel.saveToJournal()` sempre passa `nil`.

**Solucao**: Linha horizontal de 5 emojis antes de salvar:
- "Pesado", "Tenso", "Neutro", "Bem", "Motivado"
- `enum MoodOption: String, CaseIterable` com propriedades `emoji` e `label`
- Inserir no `VoiceRecordingSheet` nas telas `transcribed` e `complete`

**Arquivos**:
- `Features/Journal/VoiceRecordingViewModel.swift` - `var selectedMood: MoodOption?`
- `Features/Journal/VoiceRecordingSheet.swift` - inserir MoodSelectorRow
- Criar `Features/Journal/MoodSelectorRow.swift`
- `Models/TherapyDomain.swift` - enum MoodOption

---

### T1.3 Reproducao de Audio
**Problema**: Audio gravado via `AudioRecorder`, persistido em `JournalEntryEntity.audioFilePath`, mas zero UI de playback. Nenhum `AVAudioPlayer` no projeto.

**Solucao**: Player inline no `JournalEntryDetailView`:
- `AudioPlayer` como `@Observable final class` com AVAudioPlayer
- `AudioPlayerView` com play/pause, Slider de progresso, duracao formatada
- Sessao de audio ja esta como `.playAndRecord` no AudioRecorder

**Arquivos**:
- Criar `Core/Audio/AudioPlayer.swift`
- Criar `DesignSystem/AudioPlayerView.swift`
- `Features/Journal/JournalEntryDetailView.swift` - inserir player condicional
- `Features/Journal/JournalEntryCard.swift` - icone de audio compacto

---

### T1.4 Therapy Modes Funcionais
**Problema**: `buildSystemPrompt(profile:)` em `OpenAITherapyEngine.swift` ignora `profile.defaultModes` e usa sempre "CBT + Estoicismo + Logoterapia" fixo. Time windows do perfil tambem ignoradas.

**Solucao**:
- Prompt dinamico baseado nos modos selecionados pelo usuario
- Cada `InterventionMode` mapeado para descricao no prompt
- Slot detection usa `profile.morningWindow/middayWindow/eveningWindow` em vez de horas hardcoded

**Arquivos**:
- `Core/Therapy/OpenAITherapyEngine.swift` - buildSystemPrompt dinamico
- `Features/Today/TodayViewModel.swift` - updateSlot() com profile windows
- `Features/Journal/VoiceRecordingViewModel.swift` - detectCurrentSlot() com profile

---

### T1.5 Status "Adiado" + Link Journal-Commitment
**Problema**: `CommitmentStatus.deferred` existe mas `nextStatus()` nunca retorna `.deferred`. `JournalEntryEntity.commitmentId` e salvo mas nenhuma UI exibe.

**Solucao**:
- Swipe-action "Adiar" no `CommitmentRow` (`.swipeActions(edge: .leading)`)
- Secao "Compromisso Relacionado" no `JournalEntryDetailView` quando `entry.commitmentId != nil`
- `TherapyRepository.fetchCommitment(id:in:)` para buscar o commitment

**Arquivos**:
- `Features/Rituals/CommitmentRow.swift` - swipeActions
- `Features/Journal/JournalEntryDetailView.swift` - secao de compromisso
- `Core/Data/TherapyRepository.swift` - fetchCommitment

---

## Tier 2 - Alto Impacto: Retencao e Diferenciacao

### T2.1 Dashboard de Insights e Estatisticas
**Problema**: `MetricEventEntity` acumula dados desde o dia 1 mas nada e exibido. Sem visualizacao de progresso.

**Inspiracao**: Daylio (Year in Pixels), Bearable (correlacoes)

**Solucao**: Nova aba "Insights" (5a aba) com:
- **MoodCalendarView**: Grade 7x4 de quadrados coloridos por humor (ultimos 28 dias)
- **StreakBadgeView**: Numero de dias consecutivos com heroNumber + accentGold
- **DistortionFrequencyChart**: Barras horizontais com frequencia de cada distorcao cognitiva
- **WeeklyConsistencyChart**: 7 capsulas (seg-dom) com consistencyScore

**Dados disponiveis**:
- `JournalEntryEntity` -> moodTag por dia (apos T1.2)
- `DailyReviewEntity` -> consistencyScore dos ultimos 30 dias
- `TherapySessionEntity` -> distortionTagsRaw agrupado por frequencia
- `CommitmentEntity` -> taxa de conclusao por dia

**Arquivos**:
- `App/ContentView.swift` - 5a aba
- Criar `Features/Insights/InsightsView.swift`
- Criar `Features/Insights/InsightsViewModel.swift`
- Criar `DesignSystem/MoodCalendarView.swift`
- Criar `DesignSystem/StreakBadgeView.swift`

---

### T2.2 Sistema de Streaks
**Impacto esperado**: +48% retencao (benchmarks da industria)

**Solucao**:
- `StreakService` (enum estatico, padrao dos repositorios) calcula:
  - `journalStreak`: dias consecutivos com >= 1 entrada
  - `ritualStreak`: dias consecutivos com DailyReviewEntity salvo
  - `longestStreak`: maior streak historico
- Exibido no TodayView entre statPills e missionCard
- Marcos com celebracao: 3 dias, 7 dias ("Foco"), 14 dias ("Consistente"), 30 dias ("Inabalavel")
- Confetti simples via Canvas (similar a MeshCanvas existente) por 2 segundos

**Arquivos**:
- Criar `Core/Data/StreakService.swift`
- `Features/Today/TodayViewModel.swift` - vars de streak
- `Features/Today/TodayView.swift` - StreakRow
- Criar `DesignSystem/StreakRow.swift`

---

### T2.3 Notificacoes Locais para Rituais
**Problema**: App depende 100% de habito pre-formado para ser aberto.

**Solucao**:
- `NotificationService` (enum estatico) usando UNUserNotificationCenter
- 3 notificacoes diarias nos horarios do perfil:
  - Manha: "Bom dia! Hora do ritual matinal. 5 min para definir sua missao."
  - Meio-dia: "Check-in rapido. Como esta sua execucao?"
  - Noite: "Hora da revisao do dia. Voce evoluiu hoje?"
- Re-engagement: notificacao 48h apos ultima abertura
- Toggle "Lembretes de Ritual" no Perfil

**Arquivos**:
- Criar `Core/Notifications/NotificationService.swift`
- `Features/Profile/ProfileView.swift` - toggle
- `Features/Today/TodayViewModel.swift` - re-engagement no load()

---

### T2.4 Edicao de Entradas do Diario
**Problema**: Erros de transcricao do Whisper (comuns com sotaque brasileiro) nao podem ser corrigidos.

**Solucao**:
- Botao "Editar" no toolbar do `JournalEntryDetailView`
- `@State isEditing` transforma texto estatico em TextEditor
- Salvar: `entry.transcribedText = editText; try? modelContext.save()`
- Opcional: re-selecao de moodTag em modo edicao

**Arquivos**:
- `Features/Journal/JournalEntryDetailView.swift`

---

## Tier 3 - Crescimento e Engajamento

### T3.1 Reflexao Guiada Diaria
**Problema**: App e 100% reativo. Woebot e Life Note lideram com check-ins proativos.

**Solucao**:
- Pergunta diaria de reflexao gerada pela IA no TodayView
- Baseada no contexto recente (distorcoes, missao, humor predominante)
- Usa `OpenAIClient.sendMessage()` (atualmente dead code) para gerar prompt simples
- Card abaixo da missao com botao "Responder" que abre VoiceRecordingSheet

**Arquivos**:
- `Features/Today/TodayViewModel.swift`
- `Features/Today/TodayView.swift`
- `Core/Network/OpenAIClient.swift` - ativar sendMessage()

---

### T3.2 Exportacao de Dados
**Inspiracao**: Bearable (export para terapeutas)

**Solucao**:
- Botao "Exportar Dados" no Perfil
- `DataExportService` gera JSON formatado dos ultimos 90 dias
- `struct ExportPackage: Codable` com journal entries, reviews, sessions
- Compartilhavel via `ShareLink` nativo do SwiftUI

**Arquivos**:
- Criar `Core/Data/DataExportService.swift`
- `Features/Profile/ProfileView.swift`

---

### T3.3 Visualizacao de ControlSplit e AvoidanceScore
**Problema**: Outputs mais sofisticados da engine (dicotomia estoica do controle) sao dados fantasma.

**Solucao**:
- Secao "Dicotomia do Controle" no JournalEntryDetailView:
  - Coluna verde: "Sob seu Controle"
  - Coluna vermelha: "Fora do seu Controle"
- `AvoidanceGauge`: arco semicircular Canvas-based de 0 a 1
  - Verde (0.0) -> Vermelho (1.0) baseado em avoidanceScore
- Desnormalizar campos de TherapySessionEntity para JournalEntryEntity

**Arquivos**:
- `Models/TherapyEntities.swift`
- `Core/Data/JournalRepository.swift`
- `Features/Journal/JournalEntryDetailView.swift`
- Criar `DesignSystem/AvoidanceGauge.swift`

---

## Tier 4 - Visao de Futuro (6-12 meses)

### T4.1 Monetizacao via StoreKit 2
- Remover dependencia da chave OpenAI do usuario
- Backend simples (Cloudflare Worker) com chave do developer
- Plano gratuito: 3 entradas/mes sem IA, historico local
- **PocketMind Pro** (R$24.90/mes): ilimitado, IA completa, insights
- **PocketMind Plus** (R$39.90/mes): + export PDF formatado, multi-turno, HealthKit
- StoreKit 2: `Product.products(for:)` + `Transaction.currentEntitlement(for:)`

### T4.2 HealthKit + Widgets
- Leitura: passos, sono (`sleepAnalysis`), HRV (`heartRateVariabilitySDNN`)
- Enriquecer `TherapyContext` com `BiometricSnapshot`
- Coach pode dizer: "Percebi que voce dormiu menos de 6h..."
- Correlacoes: humor pesado vs. sono curto, motivado vs. passos altos
- Widgets: "Humor de Hoje" e "Streak" na home screen via WidgetKit

### T4.3 Sessoes Multi-Turno Conversacionais
- Transformar RitualActionCard em interface de chat multi-turno
- `conversationHistory: [Message]` acumulado no RitualsViewModel
- Usar as 6 fases de `SessionPhase` (todas dead code hoje):
  - intake -> diagnosis -> intervention -> commitment -> followup -> review
- UI evolui para ScrollView de bolhas de conversa
- Coach faz perguntas de acompanhamento baseadas nas respostas anteriores

---

## Jornada do Usuario: Antes vs. Depois

### ANTES (Hoje)
```
Instala > Dashboard vazio > Nao sabe o que fazer > Procura aba Perfil >
"Chave OpenAI?" > Nao sabe > Abandona
```

### DEPOIS (Tier 1+2 implementados)
```
Instala > Onboarding guiado (nome, chave, preferencias) >
Pergunta inicial processada pela IA > Dashboard com missao personalizada >

[Manha - Notificacao]
Abre app > Ve streak atual > Ritual em 5min > Seleciona humor >
Recebe missao e compromisso >

[Almoco - Notificacao]
Check-in rapido > "Executei" ou "Preciso adiar" >

[Noite - Notificacao]
Review do dia > Vitorias, friccoes, licao >
Streak atualizado > Insights mostram progresso semanal >

[Semana 2+]
Insights revelam: "Suas principais distorcoes: catastrofizacao (78%)"
"Humor pesado correlaciona com noites sem revisao"
Missoes ficam mais precisas com contexto acumulado
```

---

## Ordem de Implementacao Recomendada

### Sprint 1 (Quick Wins - Desbloquear Valor Existente)
1. T1.4 Therapy Modes funcionais
2. T1.2 MoodTag UI
3. T1.3 Audio playback
4. T1.5 Deferred + commitment link

### Sprint 2 (Onboarding + Engajamento)
5. T1.1 Onboarding completo
6. T2.2 Streaks

### Sprint 3 (Retencao)
7. T2.3 Notificacoes locais
8. T2.1 Dashboard Insights
9. T2.4 Edicao de entradas

### Sprint 4 (Diferenciais)
10. T3.1 Reflexao guiada diaria
11. T3.2 Exportacao de dados
12. T3.3 ControlSplit + AvoidanceGauge

### Sprint 5+ (Futuro)
13. T4.1 StoreKit 2 + backend
14. T4.2 HealthKit + Widgets
15. T4.3 Multi-turno conversacional

---

## Limpeza de Dead Code (durante implementacao)

| Item | Arquivo | Acao |
|------|---------|------|
| `AppConfig` struct | `Models.swift` | Remover (nunca usada) |
| `showResults` state | `RitualActionCard.swift` | Remover (nunca lido) |
| `NSSpeechRecognitionUsageDescription` | `Info.plist` | Remover (nao usa SFSpeechRecognizer) |
| `sendMessage()` | `OpenAIClient.swift` | Reutilizar para T3.1 (reflexao diaria) |
| Info.plist version | `Info.plist` | Alinhar com project.yml (2.1) |

---

## Verificacao pos-Sprint

```bash
# 1. Gerar projeto
xcodegen generate

# 2. Build
xcodebuild -project PocketMind.xcodeproj -scheme PocketMind \
  -destination 'id=66EF7D4C-F839-484E-9289-F4601BD4E29A'

# 3. Verificar que nao ha regressoes
# - Journal flow: gravar -> transcrever -> coach -> salvar
# - Ritual flow: selecionar slot -> executar ritual -> compromisso
# - Profile: salvar -> recarregar -> dados mantidos
# - SwiftData: entidades novas/modificadas sem crash
```

---

*Documento gerado em 22/02/2026. Baseado em pesquisa de mercado e analise do codebase PocketMind v2.1.*
