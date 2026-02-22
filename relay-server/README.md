# PocketMind Relay Server

Relay mínimo para OpenAI Realtime API.

## Endpoints
- `GET /v1/health`
- `POST /v1/realtime/session`
- `WS /v1/realtime/bridge/:sessionId`

## Rodar localmente
```bash
cd relay-server
cp .env.example .env
npm install
npm run dev
```

## Observações
- Não persiste conteúdo das conversas.
- Logs devem permanecer técnicos e sem payload sensível.
