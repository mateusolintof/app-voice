# Roadmap de Upgrade: OpenAI Realtime API

Este documento detalha o plano técnico para migrar o PocketMind da arquitetura atual (REST/Arquivo) para a **OpenAI Realtime API** (WebSocket/Streaming), proporcionando uma experiência de conversa fluida e com latência ultrabaixa.

## 1. Mudança de Arquitetura

### Atual (REST)
- **Fluxo**: Gravar Áudio -> Salvar Arquivo -> Upload (Whisper) -> Texto -> Enviar Texto (GPT-4o) -> Resposta Texto.
- **Latência**: 3 a 6 segundos.
- **Interação**: Turn-based (um fala, depois o outro).

### Futura (Realtime API)
- **Fluxo**: Conexão WebSocket Persistente. Áudio é enviado e recebido em "chunks" (pedaços) de milissegundos continuamente.
- **Latência**: ~300ms (Conversa natural).
- **Interação**: Full-Duplex (ambos podem falar e ouvir ao mesmo tempo, permite interrupções).

## 2. Componentes Necessários

### A. Relay Server (Servidor Intermediário)
**Crítico para Segurança.** A Realtime API usa WebSockets diretos. Não podemos deixar a API Key no app iOS, pois ela ficaria exposta em uma conexão persistente.
- **Tecnologia**: Node.js ou Python (FastAPI).
- **Função**:
    1. Recebe conexão WebSocket do App iOS.
    2. Autentica o usuário.
    3. Abre conexão WebSocket com a OpenAI (`wss://api.openai.com/v1/realtime`).
    4. Repassa os eventos de áudio e texto entre os dois (Proxy).

### B. Novo Motor de Áudio (iOS)
Substituir `AVAudioRecorder` (que grava arquivos) por `AVAudioEngine` (que manipula buffers de áudio em tempo real).
- **Input (Microfone)**: Capturar PCM 16-bit, 24kHz. Converter para Base64 e enviar via WebSocket a cada X ms.
- **Output (Speaker)**: Receber chunks de áudio Base64 da API, decodificar e tocar imediatamente no `AVAudioPlayerNode` sem esperar a frase acabar.

### C. Gerenciamento de Estado e Eventos
A lógica deixa de ser linear e passa a ser baseada em eventos assíncronos:
- `input_audio_buffer.append`: Enviando voz do usuário.
- `input_audio_buffer.commit`: Usuário parou de falar (VAD detectou silêncio).
- `response.audio.delta`: Recebendo áudio da IA.
- `response.audio_transcript.done`: Legenda do que a IA falou.
- `response.cancel`: Usuário interrompeu a IA.

## 3. Plano de Implementação (Passo a Passo)

### Fase 1: Backend (Relay Server)
1. Criar servidor Node.js simples.
2. Implementar endpoint `/token` ou `/socket` que conecta na OpenAI.
3. Testar conexão via terminal/script antes de ir para o iOS.

### Fase 2: Cliente iOS (Networking)
1. Adicionar biblioteca de WebSocket (ou usar `URLSessionWebSocketTask` nativo).
2. Criar `RealtimeClient` para gerenciar conexão, reconexão e envio de eventos JSON.

### Fase 3: Cliente iOS (Áudio)
1. Implementar `AudioStreamManager`.
2. Configurar `AVAudioEngine` para input (mic) e output (speaker) simultâneos.
3. Sincronizar o envio de áudio com a conexão WebSocket.

### Fase 4: UI e Refinamento
1. Criar UI de "Chamada" (animação de ondas sonoras ativas).
2. Implementar botão de "Interromper" (ou Tap-to-Interrupt).
3. Testar VAD (Voice Activity Detection) para saber quando o usuário parou de falar automaticamente.

## 4. Estimativa de Custo
- **Realtime API**: É cobrada por minuto de áudio (input e output) e tokens de texto.
- **Custo Aproximado**: ~$0.06 (6 centavos de dólar) por minuto de conversa.
- **Comparação**: É significativamente mais caro que a API Whisper + GPT-4o padrão, mas entrega uma experiência "mágica".

## 5. Conclusão
A migração é complexa e exige conhecimentos avançados de manipulação de áudio e sockets. Recomendamos estabilizar a versão 2.0 (Transcription First) antes de iniciar essa migração.
