# Journal (Diario)

## O que e essa pasta?

Essa e a funcionalidade principal do app: o **diario de voz**. O usuario grava um audio, o app transcreve usando a API Whisper da OpenAI, e opcionalmente envia o texto para o "Coach" (GPT-4o) que devolve um diagnostico cognitivo completo.

Pense assim: **e o "caderno do terapeuta" do usuario**, mas em vez de escrever, ele fala.

---

## Como funciona o fluxo completo?

```
Usuario abre a aba "Diario"
       |
       v
  [JournalView] -- mostra lista de entradas salvas
       |
       | toca no botao de microfone flutuante
       v
  [VoiceRecordingSheet] -- abre como sheet modal
       |
       | grava audio via AudioRecorder
       | para a gravacao
       v
  [VoiceRecordingViewModel] -- envia audio para Whisper (transcricao)
       |
       | texto transcrito aparece na tela
       | usuario pode editar o texto
       | usuario seleciona humor (MoodSelectorRow)
       |
       | opcao 1: "Enviar para Coach" --> GPT-4o processa
       | opcao 2: "Salvar sem Coach"  --> salva direto
       v
  [JournalRepository] -- salva no SwiftData (JournalEntryEntity)
       |
       v
  Entrada aparece na lista do JournalView
       |
       | usuario toca na entrada
       v
  [JournalEntryDetailView] -- mostra tudo: texto, resposta IA,
                               distorcoes, audio player, compromisso
```

---

## Arquivos e o que cada um faz

### JournalView.swift
**O que e**: A tela principal da aba "Diario". E uma lista de entradas agrupadas por dia ("Hoje", "Ontem", datas anteriores).

**Pontos-chave**:
- Linha 7: `showRecordingSheet` controla se o modal de gravacao esta aberto
- Linha 37: Barra de busca (`searchable`) filtra por texto transcrito, resposta da IA e humor
- Linha 54-77: Skeleton loading (animacao de carregamento com shimmer)
- Linha 87-89: `NavigationLink` leva para a tela de detalhes
- Linha 91-98: Context menu com opcao "Apagar" (segura na entrada)
- Linha 159-179: Snackbar de "desfazer" apos apagar (aparece por 4 segundos)

**Onde mexer para melhorar**:
- Para adicionar **filtro por humor**: crie um Picker acima da lista que filtra `vm.filteredEntries` por `moodTag`
- Para adicionar **filtro por data**: crie um DatePicker que filtra por `createdAt`
- Para melhorar o **empty state** (linha 127): adicione uma animacao Lottie ou um tutorial visual
- Para adicionar **busca por distorcoes cognitivas**: inclua `$0.distortionTagsRaw` no filtro da linha 31 do ViewModel

---

### JournalViewModel.swift
**O que e**: O "cerebro" da JournalView. Carrega, filtra, agrupa, deleta e desfaz entradas.

**Pontos-chave**:
- Linha 5-10: `LoadingState` controla os estados de carregamento (idle, loading, loaded, error)
- Linha 21-25: `loadEntries` busca todas as entradas do SwiftData via `JournalRepository`
- Linha 27-35: `filteredEntries` filtra em tempo real conforme o usuario digita na busca
- Linha 37-59: `groupedEntries` agrupa por dia com logica "Hoje > Ontem > data completa"
- Linha 61-76: `deleteEntry` apaga mas guarda referencia por 4 segundos para undo

**Onde mexer para melhorar**:
- Para adicionar **paginacao** (performance com muitas entradas): mude `fetchAllEntries` para aceitar `limit` e `offset`
- Para adicionar **ordenacao customizada**: adicione uma propriedade `sortOrder` e mude `groupedEntries`
- Para implementar **favoritos**: adicione um campo `isFavorite` na entidade e um toggle na UI
- Linha 78-90: O `undoDelete` recria a entrada do zero — se voce adicionar mais campos na entidade, precisa atualizar aqui tambem

---

### VoiceRecordingSheet.swift
**O que e**: O modal que aparece quando o usuario quer gravar. Tem 6 estados visuais: idle, recording, transcribing, transcribed, processingAI, complete.

**Pontos-chave**:
- Linha 16-29: Switch que muda a tela inteira baseado no estado atual
- Linha 53: `interactiveDismissDisabled` impede fechar arrastando enquanto grava
- Linha 134-169: `transcribedView` — apos transcrever, mostra: texto editavel + seletor de humor + 3 botoes (coach, salvar, regravar)
- Linha 173-263: `completeView` — apos o coach responder, mostra: texto do usuario + resposta IA + distorcoes + compromisso + humor + salvar
- Linha 267-301: Botoes customizados de gravar/parar com estilo circular gradiente

**Onde mexer para melhorar**:
- Para adicionar **timer visivel na transcricao**: mostre quanto tempo esta demorando no estado `transcribing`
- Para adicionar **opcao de digitar em vez de gravar**: crie um 7o estado `typing` com TextEditor direto
- Para melhorar o **feedback de gravacao**: adicione um indicador de volume (ja existe `WaveformView` no estado recording)
- Para adicionar **historico de conversas multi-turno**: acumule multiplos turns em vez de substituir `lastTurn`

---

### VoiceRecordingViewModel.swift
**O que e**: Gerencia toda a logica de gravacao, transcricao, envio para coach e salvamento. E o arquivo mais complexo da pasta.

**Pontos-chave**:
- Linha 5-12: `RecordingState` — os 6 estados possiveis da gravacao
- Linha 25: `AudioRecorder` — gerencia microfone e arquivo de audio
- Linha 27: `TherapyEngine` — interface para o GPT-4o (coach)
- Linha 38-57: `startRecording` — verifica permissao, inicia gravacao, comeca timer de duracao
- Linha 59-65: `stopRecording` — para gravacao e inicia transcricao automaticamente
- Linha 79-99: `sendToCoach` — monta contexto terapeutico e envia para GPT-4o
- Linha 101-138: `saveToJournal` — salva tudo (texto, audio, resposta IA, humor, compromisso, metricas)
- Linha 196-219: `detectCurrentSlot` — detecta se e manha/meio-dia/noite usando as time windows do perfil

**Onde mexer para melhorar**:
- Para adicionar **limite de duracao de gravacao**: no timer (linha 51), verifique se `recordingDuration > maxDuration` e pare automaticamente
- Para melhorar **deteccao de silencio**: use os niveis de audio (`audioLevels`) para parar gravacao apos X segundos de silencio
- Para adicionar **multiplas gravacoes por entrada**: acumule transcricoes em vez de substituir `transcribedText`
- Para salvar **rascunhos**: salve `transcribedText` em UserDefaults quando o usuario fecha sem salvar
- Linha 221-242: `formatAIResponse` — e aqui que a resposta da IA e formatada para texto legivel. Se quiser mudar o formato visual, mexa aqui

---

### JournalEntryCard.swift
**O que e**: O card que aparece na lista do diario. Mostra preview da entrada com hora, humor, texto, resposta IA e tags de distorcoes.

**Pontos-chave**:
- Linha 10-15: Barra colorida na esquerda indica o slot (manha=dourado, tarde=violeta, noite=violeta escuro)
- Linha 20-22: Mostra hora da entrada
- Linha 24-28: Icone de waveform aparece se tem audio gravado
- Linha 32-41: Badge de humor com emoji
- Linha 51-65: Preview da resposta da IA com icone de cerebro
- Linha 68-80: Tags de distorcoes cognitivas (maximo 3 visiveis)

**Onde mexer para melhorar**:
- Para adicionar **indicador de favorito**: coloque um icone de estrela no canto superior direito
- Para mostrar **mais informacoes no preview**: adicione `meaningAnchor` ou `rawReality`
- Para customizar **cores por humor**: mude o background do card baseado no `moodTag`
- Para adicionar **swipe actions**: implemente `.swipeActions` para apagar, favoritar ou compartilhar

---

### JournalEntryDetailView.swift
**O que e**: A tela completa de uma entrada. Mostra todos os dados: data, audio player, texto, resposta IA, realidade crua, reenquadramento, ancora de sentido, distorcoes e compromisso vinculado.

**Pontos-chave**:
- Linha 34-36: Audio player inline (so aparece se tem audio gravado)
- Linha 39-50: Bolha do usuario (texto transcrito)
- Linha 55-70: Bolha do coach (resposta da IA)
- Linha 73-81: "Realidade Crua" — o diagnostico direto da IA
- Linha 84-92: "Reenquadramento" — a versao reestruturada do pensamento
- Linha 95-109: "Ancora de Sentido" — o proposito/significado identificado (com glow dourado)
- Linha 112-135: Tags de distorcoes cognitivas em FlowLayout (layout que quebra linha)
- Linha 137-167: Compromisso vinculado a essa entrada (se existir)
- Linha 176-179: Animacao de entrada com spring suave e delay

**Onde mexer para melhorar**:
- Para adicionar **edicao do texto transcrito**: use `@State var isEditing` e troque `Text` por `TextEditor` condicionalmente
- Para adicionar **compartilhamento**: toolbar button com `ShareLink` gerando texto formatado
- Para mostrar **ControlSplit** (dicotomia do controle): crie duas colunas (verde/vermelha) com os arrays `underControl` e `notUnderControl`
- Para mostrar **AvoidanceScore**: crie um gauge semicircular mostrando o score de 0 a 1
- Linha 202-246: `FlowLayout` — layout customizado para tags. Reutilize em qualquer lugar que precise de tags que quebram linha

---

### MoodSelectorRow.swift
**O que e**: Componente reutilizavel que mostra 5 opcoes de humor em linha (Pesado, Tenso, Neutro, Bem, Motivado) com emojis.

**Pontos-chave**:
- Linha 4: `@Binding var selectedMood` — conecta com o ViewModel pai
- Linha 20-47: Cada chip tem emoji + label, com estados visual e haptico
- Toque seleciona, toque novamente deseleciona (toggle)

**Onde mexer para melhorar**:
- Para adicionar **mais opcoes de humor**: edite `MoodOption` em `Models/TherapyDomain.swift`
- Para mudar o **layout**: troque `HStack` por um `LazyVGrid` para mostrar em grid
- Para adicionar **cores customizadas por humor**: mude o background do chip com base no `mood` especifico
- Para adicionar **intensidade**: inclua um slider dentro de cada humor (ex: "um pouco tenso" vs "muito tenso")

---

### RecordFloatingButton.swift
**O que e**: O botao flutuante de microfone que aparece na parte inferior da JournalView. Tem uma animacao de pulso contínua para chamar atencao.

**Pontos-chave**:
- Linha 5: `isPulsing` controla a animacao de anel expansivo
- Linha 16-19: Anel externo que pulsa (cresce e some)
- Linha 22-28: Botao principal com gradiente e sombra dupla
- Linha 32: `PressScaleButtonStyle` da feedback tatil ao tocar

**Onde mexer para melhorar**:
- Para adicionar **estados visuais** (ex: gravando = vermelho): aceite um parametro `isRecording`
- Para mudar a **posicao**: ajuste o `.padding(.bottom)` na JournalView
- Para adicionar **menu de opcoes**: use um `.contextMenu` ou `Menu` com opcoes "Gravar" / "Digitar"
