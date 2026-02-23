# Network (Rede)

## O que e essa pasta?

Essa pasta contem o **cliente HTTP que conversa com a OpenAI**. Todo request que o app faz para a internet passa por aqui: transcricao de audio (Whisper) e chat com IA (GPT-4o).

Pense assim: e o **"carteiro"** que leva as mensagens do app ate a OpenAI e traz as respostas de volta.

---

## Como funciona?

```
Qualquer parte do app precisa da OpenAI
       |
       v
  [OpenAIClient] -- classe que faz os requests HTTP
       |
       | Funcao 1: transcribeAudio()
       |   App envia arquivo .m4a -> OpenAI Whisper -> texto transcrito
       |
       | Funcao 2: sendMessage()
       |   App envia mensagens -> GPT-4o -> resposta em texto livre
       |   (usada para chat simples, atualmente nao chamada)
       |
       | Funcao 3: sendStructuredMessage()
       |   App envia mensagens -> GPT-4o -> resposta em JSON puro
       |   (usada pelo OpenAITherapyEngine para respostas estruturadas)
       v
  Resposta volta e e processada pelo ViewModel ou Engine
```

---

## Arquivo e o que faz

### OpenAIClient.swift
**O que e**: Cliente HTTP que abstrai a API da OpenAI. Usa `URLSession` nativo do iOS (sem dependencias externas).

#### As 3 funcoes publicas:

**1. `transcribeAudio(fileURL:apiKey:)` (linha 7-25)**
Envia um arquivo de audio para a API Whisper e recebe texto transcrito.
- Linha 8-9: Endpoint: `POST /v1/audio/transcriptions`
- Linha 16-17: Content-Type: `multipart/form-data` (upload de arquivo)
- Linha 18: Corpo montado por `createMultipartBody` (lida com boundary e encoding)
- Linha 23: Decodifica `TranscriptionResponse` (apenas campo `text`)
- **Modelo usado**: `whisper-1` (hardcoded na linha 98)

**2. `sendMessage(messages:apiKey:model:)` (linha 27-38)**
Chat simples sem formato forcado. Envia mensagens e recebe texto livre.
- **Status atual**: Dead code — nao e chamada por ninguem. Foi planejada para reflexao diaria (Tier 3 do roadmap)
- **Modelo padrao**: `gpt-4o`

**3. `sendStructuredMessage(messages:apiKey:model:)` (linha 40-53)**
Chat com resposta forcada em JSON. E a funcao mais usada.
- Linha 46: `"response_format": ["type": "json_object"]` — forca a IA a responder JSON valido
- Linha 47: `"temperature": 0.4` — respostas mais deterministicas (menos criativas, mais consistentes)
- **Modelo padrao**: `gpt-4o`

#### Funcoes auxiliares:

**`performJSONRequest(path:body:apiKey:)` (linha 55-69)**
Funcao interna que monta o URLRequest com headers, body JSON e faz a chamada.

**`validateHTTP(response:data:)` (linha 71-84)**
Valida que o status HTTP e 2xx. Se nao for, extrai a mensagem de erro do body.

**`createMultipartBody(fileURL:boundary:)` (linha 86-102)**
Monta o corpo multipart/form-data para upload de audio. Inclui:
- O arquivo de audio com MIME type `audio/m4a`
- O nome do modelo (`whisper-1`)

#### Structs de resposta:

**`TranscriptionResponse` (linha 105-107)**
Resposta simples do Whisper com apenas `text`.

**`ChatCompletionResponse` (linha 109-119)**
Resposta do GPT com array de `choices`, cada um com uma `message` contendo `content`.

---

## Onde mexer para melhorar

### Facil (poucas linhas)
- **Mudar modelo**: troque `"gpt-4o"` por `"gpt-4o-mini"` para gastar menos. Ou aceite como parametro
- **Mudar temperatura**: aumente `0.4` para `0.7` se quiser respostas mais variadas
- **Adicionar timeout**: `request.timeoutInterval = 30` para evitar espera infinita
- **Adicionar idioma no Whisper**: no `createMultipartBody`, adicione um campo `language` com valor `"pt"` para melhorar transcricao em portugues

### Medio (algumas horas)
- **Retry automatico**: se receber erro 429 (rate limit) ou 5xx (servidor), espere e tente novamente
- **Streaming de respostas**: use `URLSession` com streaming para mostrar a resposta da IA em tempo real (como o ChatGPT faz)
- **Controle de gastos**: salve tokens usados (campo `usage` da resposta) e mostre ao usuario
- **Multiplos providers**: crie um protocolo `AIClient` e implemente versoes para OpenAI, Anthropic, Google, etc.

### Avancado (1+ dia)
- **Backend proprio**: em vez de chamar a OpenAI direto do app, crie um servidor intermediario. Vantagens:
  - Chave API fica no servidor (mais seguro)
  - Controle de rate limiting por usuario
  - Possibilidade de cache
  - Logs de uso centralizados
- **Certificado pinning**: para seguranca extra, valide o certificado SSL da OpenAI
- **Cache inteligente**: se o usuario enviar input muito parecido com um recente, retorne resposta cacheada

---

## Detalhes tecnicos importantes

### Sobre o multipart/form-data (linha 86-102)
Esse e o formato que a API do Whisper exige para receber arquivos. O codigo monta manualmente os "pedacos" do corpo:
```
--boundary
Content-Disposition: form-data; name="file"; filename="audio.m4a"
Content-Type: audio/m4a

[bytes do arquivo]
--boundary
Content-Disposition: form-data; name="model"

whisper-1
--boundary--
```

Se voce precisar enviar **parametros extras** para o Whisper (como idioma ou prompt), adicione mais blocos `--boundary` seguindo o mesmo padrao.

### Sobre JSON mode (linha 46)
O `"response_format": ["type": "json_object"]` garante que o GPT-4o retorne JSON valido. Sem isso, a IA pode envolver a resposta em markdown (```json ... ```) ou adicionar texto antes/depois, quebrando o parsing.

### Sobre a temperature (linha 47)
- `0.0` = totalmente deterministico (mesma entrada = mesma saida)
- `0.4` = leve variacao (atual — bom para terapia)
- `1.0` = muito criativo/aleatorio
- `2.0` = maximo de aleatoriedade

Para terapia, valores baixos (0.3-0.5) sao recomendados para consistencia.
