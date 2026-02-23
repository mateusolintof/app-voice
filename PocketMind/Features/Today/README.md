# Today (Hoje)

## O que e essa pasta?

Essa e a **tela inicial do app** — o dashboard que o usuario ve ao abrir. Mostra uma visao geral do dia: saudacao, progresso, missao, slot atual, acoes rapidas e ultima entrada do diario.

Pense assim: e o **"painel do dia"** que responde a pergunta "como estou indo hoje?".

---

## Como funciona?

```
App abre (apos onboarding)
       |
       v
  [TodayView] -- primeira aba do TabView
       |
       | TodayViewModel.load() carrega tudo do SwiftData:
       |   - Saudacao personalizada (Bom dia/tarde/noite + nome)
       |   - Slot atual (manha/meio-dia/noite) baseado no perfil
       |   - Missao do dia (ultima meaningAnchor salva)
       |   - Stats: entradas de hoje, compromissos, revisao
       |   - Ultima entrada do diario
       v
  Dashboard visual com:
       |
       | [Saudacao] -- "Bom dia, Mateus"
       | [Anel de Progresso] -- % de compromissos concluidos
       | [3 Stat Pills] -- entradas | compromissos | revisao
       | [Mission Card] -- missao do dia (com glow dourado)
       | [Slot Indicator] -- "Manha" com icone pulsante
       | [Quick Actions] -- "Gravar Pensamento" + "Iniciar Ritual"
       | [Recent Entry] -- preview da ultima entrada
```

---

## Arquivos e o que cada um faz

### TodayView.swift
**O que e**: A View principal do dashboard. Composta por varias secoes empilhadas em ScrollView.

**Pontos-chave**:
- Linha 8: `ringProgress` — animacao do anel de progresso (comeca em 0 e anima ate o valor real)
- Linha 29-36: Background com `AnimatedMeshBackground` translucido (efeito premium)
- Linha 56-67: **Saudacao** — mostra "Bom dia/tarde/noite" + nome + data por extenso
- Linha 71-93: **Anel de Progresso** — circulo com porcentagem de compromissos concluidos. Usa `trim` para o arco e `brandGradient` para a cor
- Linha 97-137: **Stat Pills** — 3 mini-cards lado a lado:
  - Entradas de hoje (icone livro)
  - Compromissos x/y (icone selo)
  - Revisao feita/pendente (icone check/circulo)
- Linha 141-159: **Mission Card** — card dourado com glow mostrando a missao do dia
- Linha 163-185: **Slot Indicator** — capsule com icone pulsante (sol/lua) mostrando o momento do dia
- Linha 189-232: **Quick Actions** — 2 cards tocaveis lado a lado:
  - "Gravar Pensamento" — abre VoiceRecordingSheet
  - "Iniciar Ritual" — muda para aba de Rituais via Notification
- Linha 237-257: **Recent Entry** — preview da ultima entrada do diario

**Onde mexer para melhorar**:
- Para adicionar **streak**: insira um `StreakRow` entre statPills e missionCard mostrando dias consecutivos
- Para adicionar **reflexao diaria da IA**: crie um card abaixo da missao com pergunta gerada pela IA
- Para adicionar **humor do dia**: mostre o ultimo MoodOption selecionado com destaque
- Para adicionar **widget**: exporte os dados do ViewModel para um App Group acessivel pelo widget
- Linha 215: `NotificationCenter.default.post(name: .switchToTab, object: 2)` — e assim que o botao "Iniciar Ritual" muda de aba. O `ContentView` escuta essa notificacao

---

### TodayViewModel.swift
**O que e**: Carrega todos os dados do dashboard a partir do SwiftData.

**Pontos-chave**:
- Linha 8-16: Propriedades do dashboard (greeting, slot, missao, counts, entry recente)
- Linha 18-26: `load()` — funcao central que chama todas as sub-funcoes. E chamada no `onAppear` e quando o usuario volta de outra tela
- Linha 28-41: `updateGreeting()` — saudacao baseada na hora + nome do UserDefaults
- Linha 43-69: `updateSlot()` — detecta o momento do dia usando as time windows do perfil (se disponivel) ou horarios padrao
- Linha 71-79: `loadMission()` — busca o ultimo `meaningAnchor` da sessao mais recente
- Linha 81-85: `loadJournalStats()` — conta entradas de hoje e pega a mais recente
- Linha 87-92: `loadCommitmentStats()` — conta total vs concluidos, calcula taxa
- Linha 94-104: `loadReviewStatus()` — verifica se ja existe revisao do dia

**Onde mexer para melhorar**:
- Para adicionar **streak de diario**: conte dias consecutivos com pelo menos 1 entrada usando `JournalRepository`
- Para adicionar **streak de rituais**: conte dias consecutivos com metricas "ritual_completed" usando `MetricEventEntity`
- Para adicionar **grafico de humor semanal**: busque `moodTag` dos ultimos 7 dias e calcule distribuicao
- Para melhorar **performance**: cache os resultados e so recarregue se `modelContext` mudou
- Para adicionar **time-based refresh**: use um Timer para atualizar o slot quando o horario muda (ex: de manha para meio-dia)
- Linha 71-79: A missao vem da **ultima sessao** independente do dia. Se quiser missao diaria, filtre por `createdAt` de hoje

---

## Como a troca de aba funciona

O botao "Iniciar Ritual" na TodayView nao faz NavigationLink — ele posta uma notificacao:
```swift
NotificationCenter.default.post(name: .switchToTab, object: 2)
```

No `ContentView.swift`, essa notificacao e capturada e muda a aba selecionada para index 2 (Rituais). Se quiser adicionar mais atalhos entre abas, use o mesmo padrao.
