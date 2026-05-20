---
description: Deploy del backend TasaVe (Cloudflare Worker) a producción
---

## Pasos para deploy backend

1. Verificar que `backend/src/index.js` tiene los endpoints correctos:
- `GET /tasa` → tasa actual con BCV + P2P + Yadio
- `GET /tasa/history?days=N` → historial
- `GET /health` → status

// turbo
2. Deploy del Worker a Cloudflare:
```
cd backend && npx wrangler deploy
```

3. Verificar health endpoint:
```
curl https://tasave-api.YOUR_SUBDOMAIN.workers.dev/health
```
Debe responder `{ "status": "ok" }`

4. Verificar endpoint de tasa:
```
curl https://tasave-api.YOUR_SUBDOMAIN.workers.dev/tasa
```
Debe incluir: `bcvUsd`, `bcvEur`, `usdtP2P`, `yadioRate`, `timestamp`, `nextUpdate`

**Nota**: El Worker usa KV binding `TASAVE_KV` configurado en `wrangler.toml`.
