import "dotenv/config";
import express from "express";
import http from "node:http";
import { URL } from "node:url";
import WebSocket, { WebSocketServer } from "ws";
const app = express();
app.use(express.json());
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const PORT = Number(process.env.PORT ?? 8787);
const REALTIME_MODEL = process.env.REALTIME_MODEL ?? "gpt-4o-realtime-preview";
if (!OPENAI_API_KEY) {
    throw new Error("Missing OPENAI_API_KEY environment variable");
}
app.get("/v1/health", (_req, res) => {
    res.status(200).json({ ok: true, service: "pocketmind-relay" });
});
app.post("/v1/realtime/session", async (req, res) => {
    try {
        const body = {
            model: REALTIME_MODEL,
            voice: req.body?.voice ?? "alloy",
            instructions: req.body?.instructions ??
                "PocketMind realtime therapist session in Portuguese do Brasil."
        };
        const response = await fetch("https://api.openai.com/v1/realtime/sessions", {
            method: "POST",
            headers: {
                "Authorization": `Bearer ${OPENAI_API_KEY}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify(body)
        });
        const text = await response.text();
        if (!response.ok) {
            return res.status(response.status).json({ error: text });
        }
        res.status(200).type("application/json").send(text);
    }
    catch (error) {
        res.status(500).json({ error: error.message });
    }
});
const server = http.createServer(app);
const wss = new WebSocketServer({ noServer: true });
server.on("upgrade", (request, socket, head) => {
    const url = new URL(request.url ?? "", `http://${request.headers.host}`);
    if (!url.pathname.startsWith("/v1/realtime/bridge/")) {
        socket.destroy();
        return;
    }
    wss.handleUpgrade(request, socket, head, (clientSocket) => {
        wss.emit("connection", clientSocket, request);
    });
});
wss.on("connection", (clientSocket) => {
    const openaiSocket = new WebSocket(`wss://api.openai.com/v1/realtime?model=${encodeURIComponent(REALTIME_MODEL)}`, {
        headers: {
            "Authorization": `Bearer ${OPENAI_API_KEY}`,
            "OpenAI-Beta": "realtime=v1"
        }
    });
    const closeBoth = () => {
        if (clientSocket.readyState === WebSocket.OPEN)
            clientSocket.close();
        if (openaiSocket.readyState === WebSocket.OPEN)
            openaiSocket.close();
    };
    clientSocket.on("message", (data) => {
        if (openaiSocket.readyState === WebSocket.OPEN) {
            openaiSocket.send(data);
        }
    });
    openaiSocket.on("message", (data) => {
        if (clientSocket.readyState === WebSocket.OPEN) {
            clientSocket.send(data);
        }
    });
    clientSocket.on("close", closeBoth);
    openaiSocket.on("close", closeBoth);
    clientSocket.on("error", closeBoth);
    openaiSocket.on("error", closeBoth);
});
server.listen(PORT, () => {
    console.log(`PocketMind relay running on http://localhost:${PORT}`);
});
