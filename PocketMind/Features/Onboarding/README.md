# Onboarding

## O que e essa pasta?

Essa pasta contem o **fluxo de primeira vez do usuario**. Quando alguem instala o app pela primeira vez, em vez de ver uma tela vazia sem saber o que fazer, ele passa por 4 telas guiadas que configuram tudo.

Pense assim: e o **"tutorial interativo"** que so aparece uma vez.

---

## Como funciona o fluxo?

```
App abre pela primeira vez
       |
       | @AppStorage("onboardingCompleted") == false
       | ContentView mostra .fullScreenCover
       v
  [OnboardingFlow] -- 4 telas em TabView paginado
       |
       | Tela 0: Boas-vindas (nome do app + descricao)
       | Tela 1: Nome do usuario
       | Tela 2: Chave OpenAI (com link + opcao de pular)
       | Tela 3: Personalizacao (confrontacao + primeiro pensamento)
       |
       | botao "Comecar" na ultima tela
       v
  [OnboardingViewModel.completeOnboarding()]
       |
       | salva nome, chave, perfil no SwiftData
       | se tem chave + pensamento: roda primeira sessao IA
       | marca onboardingCompleted = true
       v
  ContentView fecha o fullScreenCover
  App abre normalmente com dados pre-populados
```

---

## Arquivos e o que cada um faz

### OnboardingFlow.swift
**O que e**: A View principal do onboarding. Mostra 4 telas em sequencia com barra de progresso e botoes de navegacao.

**Pontos-chave**:
- Linha 8: `@Binding var isCompleted` — quando vira `true`, o ContentView fecha o modal
- Linha 22-27: `TabView` com `.page(indexDisplayMode: .never)` — navegacao por swipe sem bolinhas
- Linha 49-59: Barra de progresso feita de capsulas que preenchem conforme avanca
- Linha 63-97: **Tela 0 (Welcome)** — icone do app, nome, descricao
- Linha 101-131: **Tela 1 (Nome)** — TextField centralizado para o nome
- Linha 135-184: **Tela 2 (API Key)** — SecureField + link para obter chave + info de seguranca
- Linha 188-256: **Tela 3 (Personalizacao)** — slider de confrontacao + TextEditor para primeiro pensamento
- Linha 260-298: Botoes de navegacao — "Voltar" (se nao e a primeira tela) + "Continuar"/"Pular"/"Comecar"

**Detalhes importantes**:
- Linha 286: Se o usuario esta na tela de API Key e nao digitou nada, o botao mostra "Pular" em vez de "Continuar"
- Linha 294: `canProceed` valida se pode avancar (ex: nome nao pode estar vazio)

**Onde mexer para melhorar**:
- Para adicionar **mais telas**: aumente `totalSteps` no ViewModel e crie novas `stepViews` com `.tag(N)`
- Para adicionar **selecao de modos terapeuticos**: crie uma tela com toggles para CBT/Estoicismo/Logoterapia
- Para adicionar **animacoes entre telas**: use `.transition()` customizado em cada step
- Para adicionar **ilustracoes**: substitua os SF Symbols por imagens custom (Lottie ou assets)
- Para adicionar **preview do app**: mostre screenshots mockados do que o usuario vai encontrar

---

### OnboardingViewModel.swift
**O que e**: Gerencia o estado do onboarding: qual tela esta ativa, dados digitados e a logica de finalizacao.

**Pontos-chave**:
- Linha 8-14: Propriedades do formulario (currentStep, userName, apiKey, confrontationLevel, initialThought)
- Linha 18-26: `canProceed` — regras de validacao por tela. Tela 1 exige nome, as outras sao opcionais
- Linha 44-97: `completeOnboarding` — a funcao mais importante:
  - Linha 46: Salva nome no UserDefaults
  - Linha 49-51: Salva chave se preenchida
  - Linha 54-61: Cria e salva perfil terapeutico com valores padrao
  - Linha 65-91: Se tem chave + pensamento, roda a IA e salva a primeira sessao
  - Linha 96: Marca onboarding como concluido

**Onde mexer para melhorar**:
- Para adicionar **validacao da chave API**: faca uma chamada de teste (ex: listar modelos) antes de avancar
- Para permitir **selecao de time windows**: adicione DatePickers para manha/tarde/noite e passe para `TherapyProfile`
- Para adicionar **analytics**: logue eventos como "onboarding_started", "step_completed", "onboarding_finished"
- Para mostrar **progresso da primeira sessao IA**: adicione estados intermediarios (tipo "Analisando seu pensamento...")
- Linha 56: Os modos terapeuticos sao hardcoded como `[.blended, .cbt, .stoic, .logotherapy]`. Se voce adicionar selecao de modos no onboarding, passe os selecionados aqui

---

## Como desabilitar/resetar o onboarding (para testar)

No simulador ou device, execute:
```swift
UserDefaults.standard.set(false, forKey: "onboardingCompleted")
```

Ou apague o app e reinstale. O flag `onboardingCompleted` e verificado no `ContentView.swift` (pasta App).
