# PocketMind v2.1 — Documentacao Tecnica

## Indice

1. [Visao Geral da Arquitetura](#visao-geral-da-arquitetura)
2. [Estrutura de Diretorios](#estrutura-de-diretorios)
3. [Camada de Dados (SwiftData)](#camada-de-dados-swiftdata)
4. [Camada de Rede (OpenAI)](#camada-de-rede-openai)
5. [Motor de Terapia](#motor-de-terapia)
6. [Audio e Transcricao](#audio-e-transcricao)
7. [Design System](#design-system)
8. [Features](#features)
9. [Fluxo de Dados](#fluxo-de-dados)
10. [Seguranca e Privacidade](#seguranca-e-privacidade)
11. [Build e Dependencias](#build-e-dependencias)
12. [Tratamento de Erros](#tratamento-de-erros)

---

## Visao Geral da Arquitetura

PocketMind segue uma arquitetura **MVVM** com camadas bem definidas:

```
┌──────────────────────────────────────────────┐
│                   Views                       │
│  TodayView · JournalView · RitualsView · ... │
├──────────────────────────────────────────────┤
│                ViewModels                     │
│  TodayViewModel · JournalViewModel · ...      │
├──────────────────────────────────────────────┤
│              Repositories                     │
│  JournalRepository · TherapyRepository        │
├──────────────────────────────────────────────┤
│            Core Services                      │
│  OpenAIClient · OpenAITherapyEngine ·         │
│  AudioRecorder                                │
├──────────────────────────────────────────────┤
│           SwiftData (Persistencia)            │
│  ModelContainer com 6 entidades               │
└──────────────────────────────────────────────┘
```

**Stack tecnologico:**
- SwiftUI (iOS 17.0+)
- SwiftData (persistencia)
- AVFoundation (gravacao de audio)
- URLSession (API OpenAI)
- XcodeGen (geracao de projeto)

---

## Estrutura de Diretorios

```
PocketMind/
├── project.yml                    # Configuracao XcodeGen
├── PocketMind/
│   ├── App/
│   │   ├── PocketMindApp.swift    # @main, ModelContainer
│   │   └── ContentView.swift      # TabView 4 abas
│   ├── DesignSystem/
│   │   ├── PMDesign.swift         # Cores, tipografia, animacoes, componentes
│   │   ├── GlassCard.swift        # Card com glass morphism
│   │   ├── GlassButton.swift      # Botao com estilos e haptics
│   │   └── WaveformView.swift     # Visualizacao de audio
│   ├── Core/
│   │   ├── Network/
│   │   │   └── OpenAIClient.swift # Cliente HTTP para OpenAI
│   │   ├── Audio/
│   │   │   └── AudioRecorder.swift # Gravacao AVFoundation + permissoes
│   │   ├── Therapy/
│   │   │   └── OpenAITherapyEngine.swift # Motor de terapia cognitiva
│   │   └── Data/
│   │       ├── TherapyRepository.swift   # CRUD de sessoes, compromissos, perfil
│   │       └── JournalRepository.swift   # CRUD de entradas do diario
│   ├── Models/
│   │   ├── Models.swift            # Message, MessageRole, AppConfig
│   │   ├── TherapyDomain.swift     # Enums, structs, protocol TherapyEngine
│   │   └── TherapyEntities.swift   # 6 @Model (SwiftData entities)
│   └── Features/
│       ├── Today/
│       │   ├── TodayView.swift
│       │   └── TodayViewModel.swift
│       ├── Journal/
│       │   ├── JournalView.swift
│       │   ├── JournalViewModel.swift
│       │   ├── JournalEntryCard.swift
│       │   ├── JournalEntryDetailView.swift
│       │   ├── VoiceRecordingViewModel.swift
│       │   ├── VoiceRecordingSheet.swift
│       │   └── RecordFloatingButton.swift
│       ├── Rituals/
│       │   ├── RitualsView.swift
│       │   ├── RitualsViewModel.swift
│       │   ├── RitualSlotPicker.swift
│       │   ├── RitualActionCard.swift
│       │   ├── CommitmentRow.swift
│       │   └── QuickReviewSheet.swift
│       └── Profile/
│           └── ProfileView.swift
```

---

## Camada de Dados (SwiftData)

### Schema

O `ModelContainer` registra 6 entidades:

```swift
Schema([
    TherapyProfileEntity.self,
    CommitmentEntity.self,
    TherapySessionEntity.self,
    DailyReviewEntity.self,
    MetricEventEntity.self,
    JournalEntryEntity.self
])
```

Configuracao: `ModelConfiguration("PocketMindTherapy")`

### Entidades

#### TherapyProfileEntity
| Campo | Tipo | Descricao |
|-------|------|-----------|
| id | UUID (unique) | Identificador |
| confrontationLevel | Int | Nivel de confrontacao (1-5) |
| defaultModesRaw | String | Modos CSV: "cbt,stoic,logotherapy,blended" |
| morningStart/End | Date | Janela do ritual matinal |
| middayStart/End | Date | Janela do ritual do meio-dia |
| eveningStart/End | Date | Janela do ritual noturno |

#### CommitmentEntity
| Campo | Tipo | Descricao |
|-------|------|-----------|
| id | UUID (unique) | ID do contrato |
| statement | String | Declaracao do compromisso |
| nextAction | String | Proxima acao concreta |
| durationMinutes | Int | Duracao estimada (5-60 min) |
| dueAt | Date | Prazo |
| accountabilityPrompt | String | Pergunta de cobranca |
| statusRaw | String | "planned", "inProgress", "completed", "deferred" |
| slotRaw | String | "morning", "midday", "evening" |
| createdAt | Date | Data de criacao |

#### TherapySessionEntity
| Campo | Tipo | Descricao |
|-------|------|-----------|
| id | UUID (unique) | Identificador |
| phaseRaw | String | Fase da sessao |
| slotRaw | String | Slot do ritual |
| inputText | String | Entrada do usuario |
| rawReality | String | Realidade crua (diagnostico) |
| reframing | String | Reenquadramento cognitivo |
| meaningAnchor | String | Ancora de sentido |
| distortionTagsRaw | String | Tags separadas por "\|" |
| underControlRaw | String | Itens sob controle, separados por "\|" |
| notUnderControlRaw | String | Itens fora de controle, separados por "\|" |
| avoidanceScore | Double | Score de evitacao (0.0-1.0) |
| followupQuestion | String | Pergunta de follow-up |
| createdAt | Date | Timestamp |

#### DailyReviewEntity
| Campo | Tipo | Descricao |
|-------|------|-----------|
| id | UUID (unique) | Identificador |
| date | Date | Data da revisao |
| winsRaw | String | Vitorias separadas por "\|" |
| frictionsRaw | String | Fricoes separadas por "\|" |
| lesson | String | Licao do dia |
| adjustmentForTomorrow | String | Ajuste para amanha |
| consistencyScore | Int | Nota de consistencia (1-5) |

#### MetricEventEntity
| Campo | Tipo | Descricao |
|-------|------|-----------|
| id | UUID (unique) | Identificador |
| name | String | Nome do evento |
| value | Double | Valor numerico |
| context | String | Contexto (slot, data, etc.) |
| createdAt | Date | Timestamp |

#### JournalEntryEntity
| Campo | Tipo | Descricao |
|-------|------|-----------|
| id | UUID (unique) | Identificador |
| transcribedText | String | Texto transcrito ou digitado |
| audioFilePath | String? | Caminho relativo do audio (JournalAudio/*.m4a) |
| aiResponse | String? | Resposta formatada do coach |
| rawReality | String? | Diagnostico da realidade |
| reframing | String? | Reenquadramento |
| meaningAnchor | String? | Ancora de sentido |
| distortionTagsRaw | String | Distorcoes cognitivas separadas por "\|" |
| moodTag | String? | Tag de humor |
| commitmentId | UUID? | ID do compromisso gerado |
| slotRaw | String | Slot detectado automaticamente |
| createdAt | Date | Timestamp |

### Repositories

#### JournalRepository (enum com metodos estaticos)

```swift
static func saveEntry(transcribedText:audioFilePath:aiResponse:turn:moodTag:commitmentId:slot:in:)
static func fetchEntries(for date: Date?, in: ModelContext) -> [JournalEntryEntity]
static func fetchAllEntries(in: ModelContext) -> [JournalEntryEntity]
static func deleteEntry(id: UUID, in: ModelContext)  // tambem remove arquivo de audio
```

#### TherapyRepository (enum com metodos estaticos)

```swift
static func currentProfile(in:) -> TherapyProfile      // busca ou cria default
static func saveProfile(_:in:)                           // upsert
static func storeSession(turn:input:slot:phase:in:)      // salva sessao
static func upsertCommitment(_:slot:in:)                 // insert ou update por ID
static func fetchCommitments(for date:in:) -> [CommitmentEntity]
static func updateCommitmentStatus(id:status:in:)
static func saveReview(date:wins:frictions:lesson:adjustment:consistencyScore:in:)
static func logMetric(name:value:context:in:)
```

---

## Camada de Rede (OpenAI)

### OpenAIClient

**Base URL:** `https://api.openai.com/v1`

| Metodo | Endpoint | Descricao |
|--------|----------|-----------|
| `transcribeAudio(fileURL:apiKey:)` | POST `/audio/transcriptions` | Whisper-1, multipart/form-data, M4A |
| `sendMessage(messages:apiKey:model:)` | POST `/chat/completions` | Chat simples, gpt-4o |
| `sendStructuredMessage(messages:apiKey:model:)` | POST `/chat/completions` | JSON mode (response_format: json_object), temp 0.4 |

**Formato do audio enviado:** M4A (MPEG4 AAC), 44.1kHz, mono, qualidade alta

**Validacao HTTP:** Status 200-299; outros geram `NSError` com body da resposta

**Modelos de resposta:**
```swift
struct TranscriptionResponse: Codable { let text: String }
struct ChatCompletionResponse: Codable {
    let choices: [Choice]
    struct Choice: Codable { let message: APIMessage }
    struct APIMessage: Codable { let content: String }
}
```

---

## Motor de Terapia

### Protocol TherapyEngine

```swift
protocol TherapyEngine {
    func runTurn(input: String, context: TherapyContext) async throws -> TherapyTurnEnvelope
    func runRitual(slot: RitualSlot, context: TherapyContext) async throws -> RitualOutput
    func runRecovery(context: TherapyContext) async throws -> RecoveryOutput
}
```

### OpenAITherapyEngine

**Metodo terapeutico:** CBT + Estoicismo + Logoterapia

**Fluxo de `runTurn()`:**
1. Verifica input critico (keywords de risco → resposta de emergencia)
2. Valida API key
3. Monta system prompt com nivel de confrontacao
4. Monta user prompt com contexto (slot, missao, compromissos pendentes, fricoes recentes)
5. Envia para GPT-4o via `sendStructuredMessage()` (JSON mode)
6. Decodifica JSON → `TherapyTurnEnvelope`
7. Erros de rede → `TherapyEngineError.networkError`
8. Erros de decodificacao → `TherapyEngineError.decodingFailed`

**Schema JSON esperado do GPT-4o:**
```json
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
```

### TherapyEngineError

| Case | Mensagem (PT-BR) |
|------|-------------------|
| `.missingAPIKey` | "Chave OpenAI nao configurada. Va em Perfil para adicionar sua chave." |
| `.invalidResponse` | "Resposta invalida do servidor. Tente novamente." |
| `.decodingFailed(detail)` | "Falha ao processar resposta da IA: {detail}" |
| `.networkError(detail)` | "Erro de rede: {detail}" |

### Deteccao de Risco Critico

Keywords monitoradas: "suicidio", "suicídio", "me matar", "tirar minha vida", "nao quero viver", "auto mutilacao", "automutilacao", "self harm"

Quando detectado:
- Retorna resposta pre-definida (sem chamar API)
- Direciona para CVV Brasil (188)
- Sugere contato de confianca imediato

---

## Audio e Transcricao

### AudioRecorder

**Classe:** `@Observable final class AudioRecorder: NSObject`

**Formato de gravacao:**
- Codec: MPEG4 AAC
- Sample rate: 44.1kHz
- Canais: 1 (mono)
- Qualidade: AVAudioQuality.high
- Extensao: .m4a

**Metering:** Timer a 30Hz (1/30s), normalizado de -60dB a 0dB

**Barras de audio:** 48 barras (array de CGFloat 0.0-1.0)

**Permissao de microfone:**
```swift
enum MicrophonePermission { case unknown, granted, denied }

func checkMicrophonePermission() async -> MicrophonePermission
// Usa AVAudioApplication.shared.recordPermission (iOS)
// Solicita permissao se .undetermined
```

**Persistencia de audio:**
- Gravacao temporaria: `FileManager.temporaryDirectory/{UUID}.m4a`
- Persistencia: `Documents/JournalAudio/{UUID}.m4a`
- Retorna caminho relativo: `"JournalAudio/{filename}"`

---

## Design System

### Cores

| Token | Hex | Uso |
|-------|-----|-----|
| brandPrimary | #5933E6 | Violeta profundo — cor principal |
| brandSecondary | #6699FF | Azul eletrico — acentos |
| brandTertiary | #8CD9F2 | Ciano claro — gradientes |
| accentGold | #FFC752 | Ouro suave — missao, destaque |
| accentAmber | #FF9933 | Ambar quente — alertas suaves |
| success | system green | Estados positivos |
| warning | system orange | Alertas |
| danger | system red | Erros, acoes destrutivas |

### Gradientes

| Nome | Composicao |
|------|------------|
| brandGradient | violet → blue → cyan (topLeading → bottomTrailing) |
| subtleGradient | violet 12% → blue 6% |
| goldGradient | gold → amber |
| waveformGradient | violet → blue → cyan (horizontal) |
| glassBorderGradient(opacity:) | white high → white low (topLeading → bottomTrailing) |

### Tipografia (design .rounded)

| Token | Spec |
|-------|------|
| heroNumber | 56pt ultraLight rounded |
| largeTitleRounded | largeTitle bold rounded |
| title1 | title bold rounded |
| title2 | title2 semibold rounded |
| title3 | title3 semibold rounded |
| headlineRounded | headline semibold rounded |
| subheadlineRounded | subheadline medium rounded |
| bodyRounded | body rounded |
| captionRounded | caption medium rounded |
| caption2Rounded | caption2 medium rounded |
| mono | system monospaced body |

### Animacoes

| Token | Response | Damping |
|-------|----------|---------|
| springSnappy | 0.35 | 0.75 |
| springGentle | 0.5 | 0.8 |
| springBouncy | 0.4 | 0.6 |

### Componentes

**GlassCard:** Material ultraThin + overlay de profundidade (white 6% top → black 3% bottom) + borda gradiente + dual shadow + glow opcional

**GlassButton:** 4 estilos (primary/secondary/danger/gold) + PressScaleButtonStyle + UIImpactFeedbackGenerator(.medium) + estado isLoading

**WaveformView:** Canvas com 48 barras, suavizacao EMA (alpha 0.35), gradiente de cor interpolado, efeito glow em barras altas (>0.3)

**AnimatedMeshBackground:** TimelineView 30fps + Canvas com 3 blobs radiais animados

**ShimmerModifier:** Gradiente linear animado horizontalmente (1.5s repeat)

**SoftShadowModifier:** Dupla sombra (ambient radius/3 + direcional radius)

**PressScaleButtonStyle:** scaleEffect 0.97 no press

---

## Features

### Tab 0: Hoje (TodayView)

**ViewModel:** TodayViewModel
- `greeting`: "Bom dia" / "Boa tarde" / "Boa noite" baseado na hora
- `currentSlot`: RitualSlot detectado automaticamente
- `todayMission`: meaningAnchor da sessao mais recente
- `todayEntryCount`: contagem de entradas do diario hoje
- `completionRate` / `completedCount` / `totalCount`: compromissos de hoje
- `hasReview`: se existe DailyReviewEntity para hoje
- `recentEntry`: primeira entrada do diario de hoje

### Tab 1: Diario (JournalView)

**ViewModel:** JournalViewModel
- `LoadingState`: idle → loading → loaded → error
- Busca textual em transcricao, resposta AI, mood tag
- Agrupamento: "Hoje", "Ontem", data formatada
- Suporte a undo de delecao (4 segundos)

**Recording Flow:** VoiceRecordingViewModel
- Estados: idle → recording → transcribing → transcribed → processingAI → complete
- `reRecord()`: volta para idle sem fechar sheet
- Timer de duracao com invalidacao em reset()
- Verifica permissao de microfone antes de gravar

### Tab 2: Rituais (RitualsView)

**ViewModel:** RitualsViewModel
- 3 slots: morning, midday, evening
- 3 acoes: Diagnostico (runTurn), Ritual (runRitual), Recovery 90s (runRecovery)
- CRUD de compromissos manuais
- `fetchRecentFrictions()`: busca fricoes dos ultimos 7 dias de DailyReviewEntity
- Verifica permissao de microfone antes de gravar

### Tab 3: Perfil (ProfileView)

- Chave OpenAI (SecureField, @AppStorage)
- Indicador de status da chave (verde/vermelho)
- Nivel de confrontacao (Slider 1-5)
- Modos de intervencao (Toggles: CBT, Estoicismo, Logoterapia, Combinado)
- Feedback visual de "Salvo!" (2 segundos)
- Versao 2.1

---

## Fluxo de Dados

### Gravacao de Pensamento (Journal)
```
Audio (mic) → AudioRecorder.startRecording()
           → AudioRecorder.stopRecording()
           → OpenAIClient.transcribeAudio() [Whisper]
           → Texto transcrito exibido para edicao
           → OpenAITherapyEngine.runTurn() [GPT-4o]
           → TherapyTurnEnvelope
           → JournalRepository.saveEntry()
           → TherapyRepository.storeSession()
           → TherapyRepository.upsertCommitment()
           → MetricEventEntity logged
```

### Ritual (Rituals)
```
Selecao de slot → Voz/texto input
               → OpenAITherapyEngine.runRitual() [GPT-4o]
               → RitualOutput
               → TherapyRepository.upsertCommitment()
               → MetricEventEntity logged
```

### Revisao do Dia (QuickReview)
```
Vitorias + Fricoes + Licao + Ajuste + Score
→ TherapyRepository.saveReview()
→ MetricEventEntity logged
```

---

## Seguranca e Privacidade

1. **API Key**: Armazenada localmente via `@AppStorage("openAIKey")` (UserDefaults). Nunca transmitida exceto para api.openai.com.
2. **Audio**: Gravado localmente em `Documents/JournalAudio/`. Enviado apenas para Whisper API para transcricao. Deletado junto com a entrada do diario.
3. **Dados de terapia**: Persistidos localmente via SwiftData. Sem sincronizacao em nuvem.
4. **Deteccao de risco**: Keywords de risco sao verificadas localmente ANTES de chamar a API. Resposta de emergencia e local, sem dados enviados.
5. **Permissao de microfone**: Verificada via `AVAudioApplication.shared.recordPermission` antes de qualquer gravacao.

---

## Build e Dependencias

### Requisitos
- Xcode 15.0+
- iOS 17.0+
- XcodeGen (`brew install xcodegen`)

### Dependencias Externas
Nenhuma. O projeto usa apenas frameworks nativos da Apple:
- SwiftUI
- SwiftData
- AVFoundation
- Foundation

### Comandos de Build
```bash
# Gerar projeto Xcode
xcodegen generate

# Build para simulador
xcodebuild -project PocketMind.xcodeproj \
  -scheme PocketMind \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -configuration Debug build
```

### Configuracao (project.yml)
- Bundle ID: `com.pocketmind.app`
- Deployment Target: iOS 17.0
- Marketing Version: 2.1

---

## Tratamento de Erros

| Camada | Tipo de Erro | Comportamento |
|--------|-------------|---------------|
| OpenAIClient | `URLError(.badURL)` | URL malformada |
| OpenAIClient | `NSError(code: statusCode)` | Erro HTTP com body da resposta |
| TherapyEngine | `.missingAPIKey` | Exibe alerta direcionando para Perfil |
| TherapyEngine | `.networkError(detail)` | Exibe mensagem de erro de rede |
| TherapyEngine | `.decodingFailed(detail)` | Exibe erro de parsing JSON |
| TherapyEngine | `.invalidResponse` | Resposta nao convertivel para UTF-8 |
| VoiceRecordingVM | Permissao negada | "Ative em Ajustes > Privacidade > Microfone" |
| VoiceRecordingVM | Arquivo indisponivel | "Arquivo de audio indisponivel" |
| VoiceRecordingVM | Chave ausente | "Configure sua chave OpenAI em Perfil" |

Todos os erros sao exibidos ao usuario via `alert()` com mensagens em Portugues do Brasil.
