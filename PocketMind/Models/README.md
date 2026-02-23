# Models (Modelos de Dados)

## O que e essa pasta?

Essa pasta contem **tudo que define a forma dos dados** no app. Sao 3 arquivos que trabalham juntos: um define as "regras do jogo" (enums e structs), outro define como os dados sao salvos no banco (SwiftData), e o terceiro define mensagens simples.

Pense assim: se o app fosse uma empresa, essa pasta seria o **organograma + formularios padrao**.

---

## Visao geral dos 3 arquivos

```
Models/
  |
  |-- TherapyDomain.swift     <-- "Regras do jogo"
  |                                Enums, structs e protocolo
  |                                Dados em memoria, sem persistencia
  |
  |-- TherapyEntities.swift   <-- "Banco de dados"
  |                                Classes SwiftData (@Model)
  |                                Dados salvos no dispositivo
  |
  |-- Models.swift             <-- "Mensagens"
                                   Struct Message + enum MessageRole
                                   Usado pelo OpenAIClient
```

### A relacao entre eles:
```
TherapyDomain.swift                    TherapyEntities.swift
(em memoria)                           (no banco SwiftData)

TherapyProfile       <-- salvo como --> TherapyProfileEntity
CommitmentContract   <-- salvo como --> CommitmentEntity
TherapyTurnEnvelope  <-- salvo como --> TherapySessionEntity
(vitorias/fricoes)   <-- salvo como --> DailyReviewEntity
(metricas)           <-- salvo como --> MetricEventEntity
(entrada do diario)  <-- salvo como --> JournalEntryEntity
```

---

## Arquivo 1: TherapyDomain.swift

### O que e?
Define **todas as regras, tipos e estruturas** que o app usa em memoria. Nada aqui e salvo diretamente — sao modelos "voadores" que vivem enquanto o app esta aberto.

### Enums (opcoes fixas)

**`SessionPhase`** (linha 3-12)
As 6 fases de uma sessao terapeutica. Hoje so `intervention` e usada de verdade. As outras (intake, diagnosis, commitment, followup, review) sao roadmap para sessoes multi-turno.
```
intake -> diagnosis -> intervention -> commitment -> followup -> review
```

**`InterventionMode`** (linha 14-30)
Os 4 metodos terapeuticos disponiveis:
- `.cbt` — Terapia Cognitivo-Comportamental
- `.stoic` — Estoicismo (dicotomia do controle)
- `.logotherapy` — Logoterapia (sentido da vida, Viktor Frankl)
- `.blended` — Combinacao de todos

**Onde mexer**: Para adicionar um novo metodo (ex: ACT, DBT), adicione um case aqui e trate em `OpenAITherapyEngine.buildMethodDescription()`.

**`RitualSlot`** (linha 32-54)
Os 3 momentos do dia com duracao sugerida:
- `.morning` — Manha (5-8 min)
- `.midday` — Meio do dia (2-4 min)
- `.evening` — Noite (6-10 min)

**`CommitmentStatus`** (linha 56-72)
Os 4 estados de um compromisso:
- `.planned` — Planejado (estado inicial)
- `.inProgress` — Em andamento
- `.completed` — Concluido
- `.deferred` — Adiado

**`MoodOption`** (linha 74-102)
As 5 opcoes de humor com emoji e label:
- `.pesado` — Pesado
- `.tenso` — Tenso
- `.neutro` — Neutro
- `.bem` — Bem
- `.motivado` — Motivado

**Onde mexer**: Para adicionar mais humores (ex: ansioso, calmo, grato), adicione cases e atualize `emoji` e `label`.

### Structs (estruturas de dados)

**`ControlSplit`** (linha 104-109)
Dicotomia do controle estoica: duas listas separando o que esta sob controle e o que nao esta.

**`TherapyProfile`** (linha 111-133)
Configuracoes do usuario: nivel de confrontacao (1-5), modos terapeuticos selecionados, e janelas de horario para cada slot.

**`CognitiveDiagnosis`** (linha 135-139)
Diagnostico cognitivo retornado pela IA: tags de distorcoes, dicotomia do controle, e score de evitacao (0 a 1).

**`CommitmentContract`** (linha 141-206)
O compromisso que a IA gera ou que o usuario cria manualmente. Tem decodificacao robusta (linha 168-201) com fallbacks para lidar com JSONs imperfeitos do GPT-4o:
- UUID invalido -> gera novo UUID
- Data mal formatada -> tenta com/sem fracao de segundos -> fallback para +1h
- Campos ausentes -> valores padrao

**Onde mexer**: Se a IA gerar campos extras que voce quer capturar, adicione propriedades aqui e trate no `init(from decoder:)`.

**`TherapyTurnEnvelope`** (linha 208-215)
A resposta completa de uma sessao. Contem: realidade crua, diagnostico, reenquadramento, ancora de sentido, compromisso e pergunta de follow-up.

**`TherapyContext`** (linha 217-233)
O contexto que e enviado para a IA a cada chamada. Inclui: perfil, slot atual, missao, compromissos pendentes e fricoes recentes.

**`RitualOutput`** (linha 235-241) e **`RecoveryOutput`** (linha 243-248)
Structs especializadas para rituais e recovery, derivadas do envelope.

**`TherapyEngine`** (linha 250-254)
Protocolo que define a interface do motor terapeutico. Tem 3 funcoes: `runTurn`, `runRitual`, `runRecovery`. Atualmente so `OpenAITherapyEngine` implementa.

**Onde mexer**: Se quiser criar um motor alternativo (ex: motor local offline), implemente esse protocolo.

---

## Arquivo 2: TherapyEntities.swift

### O que e?
Define as **6 tabelas do banco de dados** usando SwiftData (`@Model`). Cada classe aqui e uma tabela.

### Padrao importante: Raw Strings
O SwiftData nao suporta enums ou arrays diretamente. Entao o app usa um padrao:
- **Enums** sao salvos como `String` (ex: `statusRaw`, `slotRaw`, `phaseRaw`)
- **Arrays** sao salvos como `String` com separador `|` (ex: `distortionTagsRaw`, `winsRaw`)

Para converter de volta:
```swift
// Raw -> Enum
let status = CommitmentStatus(rawValue: entity.statusRaw) ?? .planned

// Raw -> Array
let tags = entity.distortionTagsRaw.split(separator: "|").map(String.init)
```

### As 6 entidades:

**1. `TherapyProfileEntity`** (linha 4-41)
Perfil terapeutico do usuario. So existe 1 no banco (upsert).
| Campo | Tipo | O que e |
|-------|------|---------|
| confrontationLevel | Int | Nivel de confrontacao (1-5) |
| defaultModesRaw | String | Modos separados por virgula ("cbt,stoic") |
| morningStart/End | Date | Janela de horario da manha |
| middayStart/End | Date | Janela de horario do meio-dia |
| eveningStart/End | Date | Janela de horario da noite |

Tem propriedade computada `profile` (linha 28-40) que converte para `TherapyProfile`.

**2. `CommitmentEntity`** (linha 43-82)
Compromissos gerados pela IA ou criados manualmente.
| Campo | Tipo | O que e |
|-------|------|---------|
| statement | String | "Vou meditar por 10 minutos" |
| nextAction | String | "Abrir app de meditacao agora" |
| durationMinutes | Int | Duracao estimada |
| dueAt | Date | Prazo |
| statusRaw | String | "planned", "inProgress", "completed", "deferred" |
| slotRaw | String | "morning", "midday", "evening" |

Tem propriedade computada `contract` (linha 67-77) que converte para `CommitmentContract`.

**3. `TherapySessionEntity`** (linha 84-115)
Cada sessao de terapia com IA. Armazena toda a resposta do GPT-4o.
| Campo | Tipo | O que e |
|-------|------|---------|
| inputText | String | O que o usuario disse |
| rawReality | String | Diagnostico cru |
| reframing | String | Reenquadramento |
| meaningAnchor | String | Ancora de sentido |
| distortionTagsRaw | String | Distorcoes separadas por \| |
| underControlRaw | String | Itens sob controle separados por \| |
| notUnderControlRaw | String | Itens fora do controle separados por \| |
| avoidanceScore | Double | Score de evitacao (0-1) |

**4. `DailyReviewEntity`** (linha 117-143)
Revisao do dia feita a noite (QuickReviewSheet).
| Campo | Tipo | O que e |
|-------|------|---------|
| winsRaw | String | Vitorias separadas por \| |
| frictionsRaw | String | Fricoes separadas por \| |
| lesson | String | Licao do dia |
| adjustmentForTomorrow | String | Ajuste para amanha |
| consistencyScore | Int | Auto-avaliacao de consistencia (1-5) |

**5. `MetricEventEntity`** (linha 145-160)
Eventos de telemetria/metricas genericas. Usado para tracking interno.
| Campo | Tipo | O que e |
|-------|------|---------|
| name | String | Ex: "journal_entry_saved", "ritual_completed" |
| value | Double | Valor numerico (geralmente 1) |
| context | String | Contexto adicional (ex: slot, data) |

Nomes de metricas existentes: `journal_entry_saved`, `session_turn_completed`, `ritual_completed`, `recovery_completed`, `manual_commitment_created`, `commitment_status_change`, `daily_review_saved`.

**6. `JournalEntryEntity`** (linha 162-210)
Entradas do diario. A entidade mais completa.
| Campo | Tipo | O que e |
|-------|------|---------|
| transcribedText | String | Texto transcrito do audio |
| audioFilePath | String? | Caminho do arquivo .m4a |
| aiResponse | String? | Resposta formatada da IA |
| rawReality | String? | Realidade crua |
| reframing | String? | Reenquadramento |
| meaningAnchor | String? | Ancora de sentido |
| distortionTagsRaw | String | Distorcoes separadas por \| |
| moodTag | String? | Humor selecionado ("pesado", "bem", etc) |
| commitmentId | UUID? | Link para o compromisso gerado |
| slotRaw | String | Slot do momento da entrada |

### Onde mexer para melhorar

- Para adicionar **favoritos**: adicione `var isFavorite: Bool = false` na `JournalEntryEntity`
- Para adicionar **categorias/tags**: adicione `var tagsRaw: String = ""` com separador `|`
- Para adicionar **localizacao**: adicione `var latitude: Double?` e `var longitude: Double?`
- Para adicionar **duracao do audio**: adicione `var audioDurationSeconds: Double?`
- Para adicionar **contagem de tokens**: adicione `var tokensUsed: Int?` na `TherapySessionEntity`

**CUIDADO com migrations**: Ao adicionar campos novos em entidades `@Model`, o SwiftData tenta fazer migration automatica. Campos novos **devem** ter valor padrao (ex: `= false`, `= ""`, `= nil`) para evitar crash. Se mudar o tipo de um campo existente, pode precisar de migration manual.

---

## Arquivo 3: Models.swift

### O que e?
Define a estrutura basica de **mensagem** usada pelo `OpenAIClient` para montar requests.

**`Message`** (linha 3-15)
Representa uma mensagem no formato da API de chat da OpenAI.
| Campo | Tipo | O que e |
|-------|------|---------|
| role | MessageRole | Quem esta falando (.user, .assistant, .system) |
| content | String | O texto da mensagem |
| timestamp | Date | Quando foi criada |

**`MessageRole`** (linha 17-21)
Os 3 papeis possiveis:
- `.system` — instrucoes de comportamento (system prompt)
- `.user` — mensagem do usuario
- `.assistant` — resposta da IA

### Onde mexer para melhorar
- Para adicionar **historico de conversa**: salve `[Message]` no SwiftData e envie como contexto
- Para adicionar **funcoes/tools**: adicione campos para function calling da OpenAI
- Para adicionar **imagens**: adicione campo `imageData: Data?` para GPT-4 Vision
