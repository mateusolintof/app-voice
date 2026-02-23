# Therapy (Motor Terapeutico)

## O que e essa pasta?

Essa pasta contem o **coracao inteligente do app**: o motor que converte o que o usuario diz em diagnostico cognitivo, reenquadramento e compromissos de acao. E ele que "faz a terapia" usando a API da OpenAI (GPT-4o).

Pense assim: se o app fosse um consultorio, essa pasta seria o **terapeuta**.

---

## Como funciona?

```
Usuario fala/digita algo
       |
       v
  ViewModel chama therapyEngine.runTurn(input, context)
       |
       v
  [OpenAITherapyEngine]
       |
       | 1. Verifica se e conteudo critico (suicidio, automutilacao)
       |    Se sim: retorna resposta de emergencia com CVV (188)
       |
       | 2. Busca chave API do UserDefaults
       |
       | 3. Monta system prompt com:
       |    - Metodo terapeutico (CBT/Estoicismo/Logoterapia)
       |    - Nivel de confrontacao (1-5)
       |    - Estrutura JSON obrigatoria
       |
       | 4. Monta user prompt com:
       |    - Texto do usuario
       |    - Slot atual (manha/tarde/noite)
       |    - Missao atual
       |    - Compromissos pendentes
       |    - Fricoes recentes
       |
       | 5. Envia via OpenAIClient.sendStructuredMessage()
       |    (response_format: json_object, temperature: 0.4)
       |
       | 6. Decodifica JSON em TherapyTurnEnvelope
       v
  Retorna estrutura com:
       - rawReality (realidade crua)
       - diagnosis (distorcoes + controle + avoidanceScore)
       - reframing (reenquadramento)
       - meaningAnchor (ancora de sentido)
       - contract (compromisso com acao e prazo)
       - followupQuestion (pergunta de cobranca)
```

---

## Arquivo e o que faz

### OpenAITherapyEngine.swift
**O que e**: Implementacao do protocolo `TherapyEngine`. Monta prompts, chama GPT-4o e decodifica respostas.

#### As 3 funcoes principais:

**1. `runTurn(input:context:)` (linha 27-61)**
A funcao mais usada. Recebe texto do usuario + contexto terapeutico, retorna diagnostico completo.
- Linha 28-30: Verifica conteudo critico primeiro (seguranca)
- Linha 32-35: Busca chave API
- Linha 37-43: Monta mensagens (system + user)
- Linha 46-50: Chama API via `sendStructuredMessage` (JSON mode)
- Linha 56-60: Decodifica resposta em `TherapyTurnEnvelope`

**2. `runRitual(slot:context:)` (linha 63-84)**
Ritual especifico do momento do dia. Nao recebe input do usuario — gera prompt interno baseado no slot.
- Linha 67-73: Prompts diferentes por slot:
  - Manha: "defina missao, obstaculo principal e compromisso executavel"
  - Meio-dia: "confrontar autoengano, recalibrar e escolher proximo passo curto"
  - Noite: "revisao objetiva, aprendizado e ajuste para amanha"
- Linha 75: Reutiliza `runTurn()` internamente

**3. `runRecovery(context:)` (linha 86-96)**
Protocolo de emergencia para retomar foco. Prompt interno fixo sobre recuperacao em 90 segundos.

#### O System Prompt (linha 100-142)

Essa e a parte mais critica do app. E aqui que voce define a **personalidade e comportamento da IA**.

**Estrutura atual**:
- Linha 104: Identidade ("terapeuta cognitivo pessoal, direto e confrontador")
- Linha 106: Metodo (dinamico, baseado nos modos selecionados)
- Linha 108-115: 8 regras de comportamento:
  1. Diagnostico claro
  2. Identificar distorcoes cognitivas
  3. Dicotomia do controle (estoicismo)
  4. Vincular acao a sentido (logoterapia)
  5. Acao de ate 15 minutos
  6. Contrato com horario
  7. Tom de confronto configuravel
  8. Resposta em JSON puro
- Linha 116-139: Schema JSON obrigatorio com exemplos reais
- Linha 140: Instrucao sobre formatos de UUID e ISO8601

**Onde mexer para melhorar o system prompt**:
- Para mudar a **personalidade da IA**: edite a linha 105. Ex: "empatico e acolhedor" vs "direto e confrontador"
- Para adicionar **idiomas**: parametrize o idioma no prompt
- Para adicionar **especializacoes**: ex: "foco em ansiedade" ou "foco em produtividade"
- Para mudar o **tamanho da acao**: altere "ate 15 minutos" para outro valor
- Para adicionar **exercicios especificos**: inclua instrucoes como "sugira um exercicio de respiracao quando detectar ansiedade"

#### Construcao dinamica de metodo (linha 144-161)

`buildMethodDescription(modes:)` — monta a descricao do metodo baseado nos modos selecionados pelo usuario no Perfil.
- Se tem `blended` ou 3+ modos: "CBT + Estoicismo + Logoterapia"
- Caso contrario: lista os modos selecionados

**Onde mexer**: Se quiser adicionar um **novo metodo terapeutico** (ex: ACT - Acceptance and Commitment Therapy), adicione um case no `InterventionMode` em `TherapyDomain.swift` e trate aqui.

#### Prompt do usuario (linha 163-189)

`buildTurnPrompt(input:context:)` — monta o que o usuario "diz" para a IA, incluindo contexto.
- Texto do usuario
- Slot atual
- Missao atual
- Compromissos pendentes (com status)
- Fricoes recentes

**Onde mexer**: Se quiser passar mais contexto para a IA (ex: humor recente, streak, dados de saude), adicione nesse prompt.

#### Verificacao de seguranca (linha 193-229)

`checkCriticalInput(input:)` — detecta conteudo de risco (suicidio, automutilacao) e retorna resposta de emergencia com o numero do CVV (188).

**IMPORTANTE**: Essa funcao e critica para seguranca. Nao remova nem desabilite.

**Onde mexer**:
- Para adicionar **mais termos criticos**: amplie o array `criticalTerms` na linha 194-197
- Para personalizar a **resposta de emergencia**: edite o `TherapyTurnEnvelope` retornado (linha 207-228)
- Para adicionar **numeros de emergencia de outros paises**: torne a resposta configuravel por locale

---

## Estruturas de dados (em TherapyDomain.swift)

O motor retorna essas estruturas — entende-las e essencial:

| Estrutura | O que e | Onde e usada |
|-----------|---------|--------------|
| `TherapyTurnEnvelope` | Resposta completa de uma sessao | Retornada por `runTurn()` |
| `CognitiveDiagnosis` | Distorcoes + controle + avoidance | Dentro do envelope |
| `CommitmentContract` | Compromisso com acao e prazo | Salvo como `CommitmentEntity` |
| `TherapyContext` | Contexto enviado para a IA | Montado pelos ViewModels |
| `TherapyProfile` | Configuracoes do usuario | Salvo pelo ProfileView |
| `RitualOutput` | Resultado de um ritual | Retornado por `runRitual()` |
| `RecoveryOutput` | Resultado de um recovery | Retornado por `runRecovery()` |

---

## Potenciais de melhoria avancados

### Qualidade da IA
- **Few-shot examples**: adicione 2-3 exemplos de respostas ideais no system prompt para melhorar consistencia
- **Historico de conversa**: em vez de enviar 1 mensagem, envie as ultimas N trocas para contexto
- **Modelo ajustavel**: permita o usuario escolher entre GPT-4o e GPT-4o-mini (mais barato)

### Robustez
- **Retry com backoff**: se a API falhar, tente novamente com delay crescente
- **Cache de respostas**: se o input for identico, retorne resposta cacheada
- **Fallback offline**: resposta generica local quando nao tem internet

### Novos motores
- **Motor local**: usar modelos on-device (ex: Apple Intelligence) para funcionar sem internet
- **Motor Claude**: trocar OpenAI por Anthropic Claude para respostas diferentes
- **Motor hibrido**: combinar multiplos modelos e escolher a melhor resposta
