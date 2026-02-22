# PocketMind v2.1 — Guia do Usuario e Documentacao Funcional

## Indice

1. [O que e o PocketMind](#o-que-e-o-pocketmind)
2. [Configuracao Inicial](#configuracao-inicial)
3. [Telas e Funcionalidades](#telas-e-funcionalidades)
4. [Jornada do Usuario](#jornada-do-usuario)
5. [Inputs Esperados e Outputs Gerados](#inputs-esperados-e-outputs-gerados)
6. [Glossario Terapeutico](#glossario-terapeutico)
7. [Perguntas Frequentes](#perguntas-frequentes)

---

## O que e o PocketMind

PocketMind e um diario terapeutico pessoal que combina gravacao de voz com inteligencia artificial para oferecer coaching cognitivo baseado em tres abordagens:

- **CBT (Terapia Cognitivo-Comportamental):** Identifica distorcoes cognitivas e padoes de pensamento disfuncionais
- **Estoicismo:** Aplica a dicotomia do controle — separa o que voce pode controlar do que nao pode
- **Logoterapia:** Conecta acoes a um proposito pessoal (ancora de sentido)

O app funciona como um ciclo diario: voce fala sobre o que esta sentindo, o coach AI analisa e propoe uma acao concreta de ate 15 minutos, e voce acompanha seus compromissos ao longo do dia.

**Idioma:** Portugues do Brasil (toda interface e respostas da IA)

---

## Configuracao Inicial

### Passo 1: Obter chave OpenAI
1. Acesse [platform.openai.com](https://platform.openai.com)
2. Crie uma conta ou faca login
3. Va em API Keys e gere uma nova chave (comeca com `sk-...`)
4. Adicione creditos a sua conta (a API e paga por uso)

### Passo 2: Configurar no app
1. Abra o PocketMind
2. Va para a aba **Perfil** (icone de pessoa)
3. Cole sua chave no campo "Chave OpenAI"
4. O indicador mudara de vermelho ("Ausente") para verde ("Configurada")
5. Ajuste o **Nivel de Confrontacao** (1 = gentil, 5 = direto e confrontador)
6. Selecione os **Modos de Intervencao** desejados
7. Toque em **Salvar Perfil**

### Passo 3: Permissao de microfone
- Na primeira gravacao, o app solicitara acesso ao microfone
- Aceite para usar a funcionalidade de voz
- Se negar, pode ativar depois em Ajustes > Privacidade > Microfone > PocketMind

---

## Telas e Funcionalidades

### Aba "Hoje" — Dashboard

A tela inicial do app. Mostra um resumo visual do seu dia.

**Elementos:**
| Elemento | Descricao |
|----------|-----------|
| Saudacao | "Bom dia", "Boa tarde" ou "Boa noite" conforme a hora |
| Data | Dia da semana, dia e mes |
| Anel de progresso | Porcentagem de compromissos concluidos hoje (animado) |
| Pills de estatistica | Numero de entradas, compromissos completos, status da revisao |
| Card de missao | Missao do dia extraida da ultima sessao de terapia (com brilho dourado) |
| Indicador de slot | Mostra o periodo atual (Manha/Meio do dia/Noite) com icone pulsante |
| Acoes rapidas | Dois botoes: "Gravar Pensamento" e "Iniciar Ritual" |
| Ultima entrada | Preview da entrada mais recente do diario |

---

### Aba "Diario" — Registro de Pensamentos

Seu diario terapeutico pessoal. Cada entrada pode incluir gravacao de voz, transcricao e analise da IA.

**Lista de entradas:**
- Agrupadas por "Hoje", "Ontem" ou data
- Busca por texto, resposta AI ou tag de humor
- Barra lateral colorida indica o periodo (ouro = manha, gradiente = meio-dia, violeta = noite)
- Delecao com "Desfazer" por 4 segundos
- Skeleton loading enquanto carrega

**Gravar novo pensamento (botao flutuante):**
1. Toque no microfone pulsante
2. Fale livremente
3. Toque para parar
4. Revise/edite o texto transcrito
5. Escolha: "Enviar para Coach" ou "Salvar sem Coach"
6. Se enviou ao coach: veja a analise completa
7. Toque em "Salvar no Diario"
8. Opcao: "Gravar novamente" em qualquer momento

**Detalhe da entrada:**
- Texto original do usuario
- Resposta do coach
- Realidade Crua (card ambar)
- Reenquadramento (card verde)
- Ancora de Sentido (card dourado)
- Distorcoes Cognitivas (tags)

---

### Aba "Rituais" — Sessoes Terapeuticas

Sessoes estruturadas para diferentes momentos do dia.

**Seletor de slot:**
| Slot | Icone | Duracao | Foco |
|------|-------|---------|------|
| Manha | Sol | 5-8 min | Definir missao, obstaculo e compromisso |
| Meio do dia | Sol baixo | 2-4 min | Confrontar autoengano, recalibrar |
| Noite | Lua | 6-10 min | Revisao objetiva, aprendizado |

**Acoes disponiveis:**

| Acao | Tipo | Descricao |
|------|------|-----------|
| **Ritual** | Principal | Executa o ritual completo do slot selecionado |
| **Diagnostico** | Secundaria | Analise cognitiva do texto/voz fornecido |
| **Recovery 90s** | Secundaria | Protocolo de recuperacao rapida apos desvio |
| **Gravar** | Auxiliar | Grava e transcreve voz |

**Compromissos:**
- Criados automaticamente pela IA ou manualmente
- Estados: Planejado → Em andamento → Concluido (ou Adiado)
- Toque no circulo de status para avancar
- Badge de status visual em cada compromisso

**Revisao do Dia (disponivel no slot Noite):**
- Anel de progresso animado
- Campos: Vitorias, Fricoes, Licao do dia, Ajuste para amanha
- Slider de consistencia (1-5)
- As fricoes sao usadas como contexto nos proximos 7 dias

---

### Aba "Perfil" — Configuracoes

| Secao | Funcionalidade |
|-------|---------------|
| Avatar | Circulo gradiente com iniciais "PM" |
| Chave OpenAI | Campo seguro + indicador verde/vermelho |
| Perfil Terapeutico | Nivel de confrontacao (1-5) + modos de intervencao |
| Salvar | Botao com feedback "Salvo!" |
| Sobre | Versao 2.1 |

---

## Jornada do Usuario

### Jornada Diaria Completa

```
                    MANHA (5h-12h)
                         │
                    ┌────┴────┐
                    │  RITUAL │  Definir missao do dia
                    │  MANHA  │  Identificar obstaculo
                    │         │  Criar compromisso
                    └────┬────┘
                         │
              ┌──────────┼──────────┐
              │          │          │
         Gravar      Executar    Check-in
        pensamento   compromisso   rapido
              │          │          │
              └──────────┼──────────┘
                         │
                  MEIO DO DIA (12h-17h)
                         │
                    ┌────┴────┐
                    │ RITUAL  │  Confrontar autoengano
                    │ MEIO-DIA│  Recalibrar rota
                    │         │  Novo compromisso curto
                    └────┬────┘
                         │
                    ┌────┴────┐
                    │ RECOVERY│  Se houve desvio:
                    │   90s   │  Reconhecer friccao
                    │         │  Propor retomada
                    └────┬────┘
                         │
                    NOITE (17h-5h)
                         │
                    ┌────┴────┐
                    │  RITUAL │  Revisao objetiva
                    │  NOITE  │  Aprendizado do dia
                    │         │  Ajuste para amanha
                    └────┬────┘
                         │
                    ┌────┴────┐
                    │ REVISAO │  Vitorias + Fricoes
                    │ DO DIA  │  Licao + Ajuste
                    │         │  Nota de consistencia
                    └─────────┘
```

### Cenarios de Uso

**Cenario 1: "Estou ansioso com uma reuniao"**
1. Usuario abre app, vai em Diario
2. Toca no microfone, fala sobre a ansiedade
3. IA transcreve: "Estou muito ansioso com a reuniao de amanha..."
4. Envia para Coach
5. Coach retorna:
   - Realidade Crua: "Voce esta projetando catastrofe em um evento futuro"
   - Distorcoes: ["catastrofizacao", "leitura_mental"]
   - Dicotomia do controle: Sob controle = preparacao; Fora = reacao dos outros
   - Reenquadramento: "A preparacao elimina 80% da ansiedade"
   - Compromisso: "Preparar 3 pontos-chave em 15 minutos"
6. Salva no diario com compromisso

**Cenario 2: "Desviei do plano, procrastinei o dia todo"**
1. Usuario vai em Rituais
2. Seleciona slot atual
3. Toca "Recovery 90s"
4. IA retorna:
   - Friccoes detectadas: ["procrastinacao", "auto_sabotagem"]
   - Acao de retomada: "Escolher a tarefa mais critica e trabalhar 15 min"
   - Compromisso criado automaticamente
5. Usuario avanca status do compromisso ao executar

**Cenario 3: Fim do dia**
1. Usuario seleciona slot Noite
2. Executa Ritual da Noite
3. Toca "Revisao do Dia"
4. Preenche vitorias, fricoes, licao
5. Da nota de consistencia
6. Fricoes sao usadas como contexto nos proximos 7 dias

---

## Inputs Esperados e Outputs Gerados

### Entrada de Voz (Journal e Rituals)

**Input esperado:**
- Audio falado em portugues (qualquer duracao)
- Conteudo: pensamentos, sentimentos, situacoes, queixas, reflexoes
- Alternativa: texto digitado diretamente no campo

**Processamento:**
1. Audio M4A enviado para Whisper API → texto
2. Texto enviado para GPT-4o com contexto terapeutico → JSON estruturado

**Output gerado (TherapyTurnEnvelope):**

| Campo | Tipo | Descricao | Exemplo |
|-------|------|-----------|---------|
| rawReality | String | Fato cru sobre a situacao | "Voce esta evitando confrontar o problema real" |
| diagnosis.distortionTags | [String] | Distorcoes cognitivas | ["catastrofizacao", "leitura_mental"] |
| diagnosis.controlSplit.underControl | [String] | O que voce pode controlar | ["Preparacao", "Atitude"] |
| diagnosis.controlSplit.notUnderControl | [String] | O que esta fora do controle | ["Opiniao alheia"] |
| diagnosis.avoidanceScore | Double | Score de evitacao (0.0-1.0) | 0.65 |
| reframing | String | Reenquadramento cognitivo | "Preparacao elimina 80% da ansiedade" |
| meaningAnchor | String | Conexao com proposito | "Seu compromisso com crescimento profissional" |
| contract.statement | String | Declaracao do compromisso | "Vou preparar 3 pontos em 15 minutos" |
| contract.nextAction | String | Acao concreta | "Abrir documento e listar 3 pontos-chave" |
| contract.durationMinutes | Int | Tempo estimado | 15 |
| contract.dueAt | Date | Prazo (ISO8601) | 2024-01-15T14:30:00Z |
| contract.accountabilityPrompt | String | Pergunta de cobranca | "Voce ja abriu o documento?" |
| followupQuestion | String | Reflexao para proximo check-in | "Que evidencia tera em 15 min?" |

### Ritual (RitualOutput)

**Input:** Slot selecionado (morning/midday/evening) + contexto atual

**Output:**
| Campo | Descricao |
|-------|-----------|
| slot | Slot executado |
| summary | Resumo da situacao (rawReality) |
| mission | Missao definida (ou mantida se ja existia) |
| contract | Compromisso gerado |
| accountabilityPrompt | Pergunta de cobranca |

### Recovery 90s (RecoveryOutput)

**Input:** Contexto atual (automatico)

**Output:**
| Campo | Descricao |
|-------|-----------|
| summary | Reenquadramento apos desvio |
| frictionDetected | Lista de friccoes identificadas |
| resetAction | Acao de retomada |
| contract | Compromisso de recuperacao |

### Revisao do Dia

**Input esperado:**
| Campo | Formato | Exemplo |
|-------|---------|---------|
| Vitorias | Texto livre separado por virgula | "Terminei relatorio, acordei cedo, li 20 paginas" |
| Fricoes | Texto livre separado por virgula | "Procrastinei 2h, comi mal, dormi tarde" |
| Licao do dia | Texto livre | "Preciso planejar a noite anterior" |
| Ajuste para amanha | Texto livre | "Definir 3 prioridades antes de dormir" |
| Consistencia | Slider 1-5 | 3 |

**Output:** DailyReviewEntity salvo localmente. Fricoes alimentam contexto dos proximos 7 dias de sessoes.

### Compromisso Manual

**Input esperado:**
| Campo | Restricoes | Exemplo |
|-------|-----------|---------|
| Compromisso | Texto obrigatorio | "Finalizar apresentacao" |
| Proxima acao | Texto obrigatorio, max 15 min | "Criar 5 slides basicos" |
| Duracao | 5-60 minutos | 15 |
| Prazo | Data e hora | Hoje, 15:00 |

**Output:** CommitmentEntity criado com status "Planejado"

---

## Glossario Terapeutico

| Termo | Definicao |
|-------|-----------|
| **Realidade Crua** | Descricao objetiva e sem filtro da situacao real do usuario |
| **Distorcao Cognitiva** | Padrao de pensamento disfuncional (ex: catastrofizacao, leitura mental, pensamento tudo-ou-nada) |
| **Dicotomia do Controle** | Principio estoico que separa o que esta sob seu controle do que nao esta |
| **Reenquadramento** | Nova perspectiva orientada a responsabilidade pessoal |
| **Ancora de Sentido** | Conexao entre a acao proposta e o proposito/sentido de vida do usuario |
| **Score de Evitacao** | Metrica (0-1) que indica o quanto o usuario esta evitando enfrentar o problema |
| **Compromisso** | Acao concreta, mensuravel, de ate 15 minutos, com prazo definido |
| **Nivel de Confrontacao** | Intensidade do tom do coach (1=gentil a 5=direto e confrontador) |
| **Slot** | Periodo do dia: Manha (5-12h), Meio do dia (12-17h), Noite (17-5h) |
| **Ritual** | Sessao terapeutica estruturada para um slot especifico |
| **Recovery 90s** | Protocolo rapido de recuperacao quando houve desvio do plano |
| **Fricoes** | Obstaculos, falhas ou pontos de atrito do dia |

---

## Perguntas Frequentes

**P: Quanto custa usar o PocketMind?**
R: O app e gratuito. Voce paga apenas pelo uso da API OpenAI (Whisper para transcricao + GPT-4o para coaching). Uma sessao tipica custa entre $0.01-0.05 USD.

**P: Meus dados sao enviados para algum servidor?**
R: Seus dados ficam 100% no dispositivo (SwiftData local). Apenas o audio gravado e enviado para a API Whisper (transcricao) e o texto para GPT-4o (coaching). A chave API fica salva localmente.

**P: Posso usar sem gravar voz?**
R: Sim. Em todas as telas de entrada, voce pode digitar diretamente no campo de texto ao inves de gravar.

**P: O que acontece se eu nao tiver conexao com a internet?**
R: Voce pode gravar e salvar pensamentos sem coach (texto puro). As funcoes que dependem da IA (transcricao, coaching, rituais) precisam de internet.

**P: Como funciona a deteccao de risco?**
R: Se o app detectar palavras relacionadas a risco de vida (suicidio, automutilacao), ele NAO envia dados para a API. Em vez disso, exibe uma resposta local com o numero do CVV Brasil (188) e orientacoes de ajuda imediata.

**P: Posso mudar o nivel de confrontacao?**
R: Sim. Va em Perfil, ajuste o slider de 1 (gentil e encorajador) a 5 (direto e confrontador), e salve.

**P: O que sao os modos de intervencao?**
R: Sao as abordagens terapeuticas usadas pelo coach:
- **CBT**: Foca em identificar e corrigir distorcoes cognitivas
- **Estoicismo**: Aplica dicotomia do controle e aceitacao
- **Logoterapia**: Conecta acoes a sentido/proposito
- **Combinado**: Usa os tres metodos integrados (recomendado)

**P: As fricoes da revisao do dia sao usadas para algo?**
R: Sim. As fricoes dos ultimos 7 dias alimentam o contexto das sessoes de terapia, permitindo que o coach faca referencias e acompanhamento de padroes recorrentes.

**P: Posso desfazer a delecao de uma entrada?**
R: Sim. Apos deletar, um botao "Desfazer" aparece por 4 segundos no fundo da tela.
