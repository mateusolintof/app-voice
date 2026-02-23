# Rituals (Rituais)

## O que e essa pasta?

Essa pasta contem o **sistema de rituais terapeuticos**. Sao sessoes estruturadas que o usuario faz em 3 momentos do dia: manha (definir missao), meio-dia (recalibrar) e noite (revisar o dia).

Pense assim: e o **"gym do cerebro"** — exercicios cognitivos com horario e acompanhamento.

---

## Como funciona o fluxo?

```
Usuario abre a aba "Rituais"
       |
       v
  [RitualsView] -- tela principal
       |
       | Secao 1: Seletor de slot (Manha/Meio-dia/Noite)
       | Secao 2: Card de acao (gravar/digitar + botoes)
       | Secao 3: Lista de compromissos do dia
       | Secao 4: Botao "Revisao do Dia" (so aparece a noite)
       |
       | usuario toca "Ritual"
       v
  [RitualsViewModel.runRitual()] -- chama OpenAITherapyEngine
       |
       | envia prompt especifico do slot (manha/tarde/noite)
       | recebe: missao, compromisso, pergunta de cobranca
       v
  Resultado aparece no RitualActionCard
  Compromisso e salvo automaticamente na lista
```

### Os 3 tipos de acao:

| Acao | O que faz | Quando usar |
|------|-----------|-------------|
| **Ritual** | Sessao completa baseada no slot atual | Rotina diaria |
| **Diagnostico** | Analise cognitiva do que o usuario digitou/gravou | Quando precisa processar um pensamento especifico |
| **Recovery 90s** | Protocolo rapido para retomar foco apos desvio | Quando saiu dos trilhos |

---

## Arquivos e o que cada um faz

### RitualsView.swift
**O que e**: A tela principal da aba "Rituais". Monta tudo: seletor de slot, card de acao, lista de compromissos e botao de revisao.

**Pontos-chave**:
- Linha 14: `RitualSlotPicker` — seletor visual de Manha/Meio-dia/Noite
- Linha 17-34: `RitualActionCard` — recebe bindings e closures para todas as acoes
- Linha 37-88: **Secao de Compromissos** — lista de `CommitmentRow` + formulario para criar novos
- Linha 46-57: Botao "+" que abre/fecha formulario de novo compromisso
- Linha 80-86: Cada `CommitmentRow` recebe callback `onStatusChange` para mudar status
- Linha 91-95: Botao "Revisao do Dia" so aparece quando o slot selecionado e "Noite"
- Linha 121-153: Formulario de novo compromisso (statement, acao, duracao, prazo)

**Onde mexer para melhorar**:
- Para adicionar **filtro de compromissos por status**: crie tabs "Todos / Pendentes / Concluidos"
- Para adicionar **contador de compromissos**: mostre "3/5 concluidos" no header
- Para o formulario de novo compromisso: adicione **sugestoes da IA** baseadas no contexto recente

---

### RitualsViewModel.swift
**O que e**: O cerebro dos rituais. Gerencia gravacao, chamadas para IA, compromissos e estado.

**Pontos-chave**:
- Linha 8-16: Propriedades de estado (slot selecionado, texto, missao, resultados das 3 acoes)
- Linha 20-27: Propriedades do formulario de novo compromisso
- Linha 33-35: `loadCommitments` — busca compromissos do dia via `TherapyRepository`
- Linha 39-56: `toggleRecording` — alterna gravacao. Ao parar, inicia transcricao automaticamente
- Linha 60-89: `runTherapyTurn` — fluxo completo de diagnostico:
  1. Monta contexto (perfil + compromissos pendentes + fricoes recentes)
  2. Envia para `therapyEngine.runTurn()`
  3. Salva sessao, compromisso e metrica
- Linha 91-121: `runRitual` — similar ao diagnostico, mas usa `therapyEngine.runRitual()` que envia prompt especifico do slot
- Linha 123-151: `runRecovery` — protocolo de recuperacao rapida com `therapyEngine.runRecovery()`
- Linha 155-182: `createCommitment` — cria compromisso manual (sem IA)
- Linha 184-188: `markStatus` — muda status de um compromisso (planejado > em andamento > concluido)
- Linha 224-255: `buildContext` — monta o `TherapyContext` com perfil, compromissos pendentes e fricoes dos ultimos 7 dias

**Onde mexer para melhorar**:
- Para adicionar **sessoes multi-turno**: acumule os turns em um array e envie historico para a IA
- Para adicionar **timer de ritual**: mostre quanto tempo falta para o ritual terminar
- Para melhorar o **contexto da IA**: adicione `recentEntry` (ultima entrada do diario) ao contexto
- Linha 241-255: `fetchRecentFrictions` busca fricoes dos ultimos 7 dias das revisoes noturnas. Aumente ou diminua o periodo conforme necessidade

---

### RitualActionCard.swift
**O que e**: O card principal onde o usuario interage com os rituais. Tem area de texto, botao de gravar, botao de ritual, diagnostico e recovery.

**Pontos-chave**:
- Linha 24-29: `TextEditor` com placeholder customizado (overlay de texto)
- Linha 44-52: Botao "Ritual" — estilo primario, full-width, com loading state
- Linha 55-90: Botoes secundarios lado a lado: "Gravar" (vermelho se gravando) + "Diagnostico"
- Linha 92-110: Botao "Recovery 90s"
- Linha 122-170: `resultSection` — mostra os resultados apos a IA responder:
  - Reenquadramento (verde)
  - Ancora de sentido (violeta com destaque)
  - Compromisso gerado (verde com selo)
  - Proxima reflexao (italico)

**Onde mexer para melhorar**:
- Para adicionar **feedback de gravacao visual**: mostre `WaveformView` durante a gravacao
- Para melhorar o **resultado**: adicione secao de "Realidade Crua" e "Distorcoes Cognitivas"
- Para adicionar **botao de copiar resposta**: coloque um `.contextMenu` com opcao de copiar
- Para adicionar **animacao de entrada nos resultados**: cada secao pode ter delay diferente

---

### CommitmentRow.swift
**O que e**: Um card que representa um compromisso individual. Mostra statement, acao, duracao, prazo e status com opcoes de interacao.

**Pontos-chave**:
- Linha 16-30: Botao circular de status — toque avanca para o proximo estado:
  - Planejado (circulo vazio) -> Em andamento (seta) -> Concluido (check verde)
  - Adiado (pause) -> Em andamento
- Linha 33-53: Informacoes do compromisso (statement, acao, duracao, hora)
- Linha 37: Texto riscado quando concluido (`strikethrough`)
- Linha 59-65: Badge de status no canto direito com cor dinamica
- Linha 68-79: **Swipe action "Adiar"** — arrasta para a direita para adiar (so se nao esta concluido ou adiado)

**Onde mexer para melhorar**:
- Para adicionar **swipe para deletar**: `.swipeActions(edge: .trailing)` com botao vermelho
- Para adicionar **notificacao no prazo**: ao criar compromisso, agende uma `UNNotification` para `dueAt`
- Para adicionar **feedback de conclusao**: animacao de confetti ou celebracao ao marcar como concluido
- Para mostrar **progresso temporal**: barra de progresso mostrando quanto tempo falta ate o prazo

---

### RitualSlotPicker.swift
**O que e**: Seletor horizontal de 3 slots (Manha, Meio-dia, Noite) com animacao de destaque (matchedGeometryEffect).

**Pontos-chave**:
- Linha 5: `@Namespace` — namespace para animacao de transicao suave entre slots
- Linha 9-48: Tres botoes lado a lado, cada um com icone + nome + duracao sugerida
- Linha 33-44: O slot selecionado tem background com gradiente animado; os outros tem material translucido
- Linha 22: `symbolEffect(.bounce)` — icone pula quando selecionado

**Onde mexer para melhorar**:
- Para adicionar **indicador de ritual feito**: mostre um check verde se o ritual daquele slot ja foi executado hoje
- Para **auto-selecionar o slot atual**: use `detectCurrentSlot()` no `onAppear`
- Para adicionar **haptic** mais sutil: ja usa `UISelectionFeedbackGenerator` (bom)

---

### QuickReviewSheet.swift
**O que e**: Modal de revisao do dia que aparece quando o usuario toca "Revisao do Dia" (so a noite). Pede vitorias, fricoes, licao e ajuste para amanha.

**Pontos-chave**:
- Linha 15: `completionRate` — porcentagem de compromissos concluidos, mostrada no anel
- Linha 22-46: Anel de progresso animado (mesmo estilo do TodayView)
- Linha 49-97: 4 campos de entrada:
  - Vitorias (icone trofeu, cor verde)
  - Fricoes (icone alerta, cor amarela)
  - Licao do dia (icone lampada, cor violeta)
  - Ajuste para amanha (icone seta, cor cyan)
- Linha 83-96: Slider de consistencia (1 a 5)
- Linha 138-163: `saveReview()` — salva via `TherapyRepository.saveReview()` e loga metrica

**Onde mexer para melhorar**:
- Para adicionar **sugestoes da IA**: preencha os campos com sugestoes baseadas nas entradas do dia
- Para adicionar **historico de revisoes**: mostre revisoes passadas em uma lista acessivel
- Para adicionar **comparacao com dia anterior**: mostre metricas do dia anterior ao lado
- Para melhorar as **fricoes**: em vez de texto livre, use tags pre-definidas selecionaveis
