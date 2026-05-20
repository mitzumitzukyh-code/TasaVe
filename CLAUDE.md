# CLAUDE.md — TasaVe Project Instructions

## Proyecto
TasaVe — App Flutter multiplataforma (Android + iOS + Web) para consultar la tasa de cambio BCV de Venezuela en tiempo real. Backend en Cloudflare Workers + KV.

- **URL de producción**: https://tasave-app.pages.dev/ (NUNCA cambiar este dominio)
- **Filosofía de diseño**: UI limpia, colores sólidos, funciones simples sin sobrecarga visual

## Idioma
Responder SIEMPRE en español (Venezuela). UI en español.

## Stack
- Flutter 3.x / Dart 3.x
- State management: SOLO Riverpod (StateNotifierProvider, FutureProvider, FutureProvider.family)
- HTTP: Dio | Storage: SharedPreferences | Charts: fl_chart
- Fonts (Google Fonts): Bebas Neue (títulos), DM Sans (cuerpo), Space Mono (mono/tasas)
- Ads: google_mobile_ads — SOLO en home_screen
- Backend: Cloudflare Workers (Wrangler CLI)

## Comandos clave
- Analizar: `flutter analyze --no-fatal-infos`
- Build web: `flutter build web --release`
- Deploy web: `npx wrangler pages deploy build/web --project-name=tasave-app`
- Deploy backend: `cd backend && npx wrangler deploy`

## Modelo principal
```dart
class TasaModel {
  final double bcvUsd;      // BCV USD oficial
  final double bcvEur;      // BCV EUR oficial
  final double? usdtP2P;    // Binance P2P top 5
  final double? yadioRate;  // Yadio.io libre
  final DateTime timestamp;
  final bool isFromCache;
  final String? bcvStatus;
  double get spreadPercent; // (P2P - BCV) / BCV * 100
}
```

## Providers
- `tasaProvider` → FutureProvider<TasaModel>
- `historyProvider` → FutureProvider.family<List<TasaHistoryEntry>, int>
- `accessibilityProvider` → StateNotifierProvider<AccessibilityNotifier, bool>
- `shellTabProvider` → StateProvider<int>
- `localStorageProvider` → Provider<LocalStorage>
- `bcvServiceProvider` → Provider<BcvService>

## API Endpoints
- `GET /tasa` → TasaModel + nextUpdate
- `GET /tasa/history?days=30` → List<TasaHistoryEntry>
- `GET /health` → { status: 'ok' }

## Reglas absolutas
1. NUNCA hardcodear tasas, porcentajes o datos — todo del API
2. NUNCA inventar valores — sin dato = "—" o "sin datos"
3. Offline first — cachear en SharedPreferences
4. Accesibilidad — textScaler 1.375x global en MaterialApp.builder
5. Colores fijos: bg=#07070A, green=#00E676, red=#FF5252, amber=#FFD740, blue=#448AFF
6. Fuentes fijas: Bebas Neue, DM Sans, Space Mono
7. Errores en español simple
8. Ads SOLO en home_screen
9. SOLO Riverpod — nunca Provider/Bloc/GetX

## Prohibiciones
- ❌ Hardcodear tasas/spreads/porcentajes
- ❌ setState en pantallas principales
- ❌ Ads en calculator o remesas
- ❌ Cambiar colores/fuentes sin aprobación
- ❌ Inventar datos falsos
- ❌ Requests sin fallback a caché
