# TasaVe 🇻🇪

App Flutter multiplataforma (Android + iOS + Web) para consultar la tasa de cambio BCV de Venezuela en tiempo real.

**URL producción**: https://tasave-app.pages.dev/

## Stack

| Capa        | Tecnología                          |
|-------------|-------------------------------------|
| Frontend    | Flutter 3.x / Dart 3.x              |
| Estado      | Riverpod                            |
| HTTP        | Dio                                 |
| Storage     | SharedPreferences                   |
| Charts      | fl_chart                            |
| Ads         | google_mobile_ads (solo home)       |
| Backend     | Cloudflare Workers + KV             |

## Diseño

- **Colores**: Rojo `#E53935` · Blanco `#FFFFFF` · Negro `#1A1A1A`
- **Fuentes**: DM Sans (sans-serif) · Space Mono (mono)
- **Offline first**: caché en SharedPreferences
- **Accesibilidad**: textScaler 1.375x

## Comandos

```bash
# Analizar
flutter analyze --no-fatal-infos

# Build web
flutter build web --release

# Deploy web
npx wrangler pages deploy build/web --project-name=tasave-app

# Deploy backend
cd backend && npx wrangler deploy

# Build APK
flutter build apk --release
```

## API

| Endpoint                    | Descripción            |
|-----------------------------|------------------------|
| `GET /tasa`                 | Tasa BCV + P2P + Yadio |
| `GET /tasa/history?days=N`  | Historial              |
| `GET /health`               | Health check           |

## Estructura

```
lib/
├── core/constants/     # Constantes (IVA, IGTF, bancos)
├── data/
│   ├── api/            # BcvService (Dio)
│   ├── cache/          # LocalStorage (SharedPreferences)
│   ├── models/         # TasaModel, TasaHistoryEntry
│   └── services/       # NotificationService
├── utils/              # Formatters, accessibility, error_monitor
└── main.dart
```

## Reglas clave

- ❌ NUNCA hardcodear tasas, spreads ni porcentajes
- ❌ NUNCA inventar valores — sin dato = "—" o "sin datos"
- ❌ Sin ads en calculadora, remesas ni scanner
- ✅ Siempre fallback a caché si no hay red
- ✅ Errores en español simple
