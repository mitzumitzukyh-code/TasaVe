# GitHub Copilot Instructions — TasaVe

## Proyecto
TasaVe es una app Flutter multiplataforma (Android + iOS + Web) para consultar la tasa de cambio BCV de Venezuela en tiempo real. Backend en Cloudflare Workers + KV.

- **URL de producción**: https://tasave-app.pages.dev/ (NUNCA cambiar este dominio)
- **Filosofía de diseño**: UI limpia, colores sólidos, funciones simples sin sobrecarga visual

## Reglas de código
- **State management**: SOLO Riverpod (StateNotifierProvider, FutureProvider, FutureProvider.family). NUNCA usar Provider, Bloc o GetX.
- **HTTP**: Dio con interceptores
- **Storage**: SharedPreferences via `localStorageProvider`
- **Charts**: fl_chart
- **Fonts**: Google Fonts — Bebas Neue (títulos), DM Sans (cuerpo), Space Mono (monoespaciado)
- **Ads**: google_mobile_ads — SOLO en home_screen, NUNCA en calculator ni remesas

## Modelo de datos principal
```dart
class TasaModel {
  final double bcvUsd;      // Tasa oficial BCV USD
  final double bcvEur;      // Tasa oficial BCV EUR
  final double? usdtP2P;    // Binance P2P promedio top 5
  final double? yadioRate;  // Yadio.io tasa libre
  final DateTime timestamp;
  final bool isFromCache;
  final String? bcvStatus;
  double get spreadPercent; // (P2P - BCV) / BCV * 100
}
```

## Reglas absolutas
1. **NUNCA hardcodear** tasas, porcentajes o textos de datos. Todo viene del API.
2. **NUNCA inventar valores** — si no hay dato, mostrar "—" o "sin datos"
3. **Offline first** — cachear en SharedPreferences, mostrar caché si no hay red
4. **Accesibilidad** — textScaler 1.375x global, toggle en ajustes, persiste en SharedPreferences
5. **Colores fijos**: bg=#07070A, green=#00E676, red=#FF5252, amber=#FFD740, blue=#448AFF
6. **Fuentes fijas**: Bebas Neue, DM Sans, Space Mono
7. **Errores** siempre en español simple, nunca códigos técnicos
8. **Idioma**: UI y respuestas en español (Venezuela)

## Providers clave
- `tasaProvider` — FutureProvider<TasaModel> (tasa actual)
- `historyProvider` — FutureProvider.family<List<TasaHistoryEntry>, int> (historial por días)
- `accessibilityProvider` — StateNotifierProvider<AccessibilityNotifier, bool>
- `shellTabProvider` — StateProvider<int> (tab activo)
- `localStorageProvider` — Provider<LocalStorage>
- `bcvServiceProvider` — Provider<BcvService>

## Deploy
- Web: `npx wrangler pages deploy build/web --project-name=tasave-app`
- Backend: `npx wrangler deploy` (desde /backend)

## Prohibiciones
- ❌ Hardcodear tasas/spreads/porcentajes
- ❌ setState en pantallas principales
- ❌ Provider/Bloc/GetX
- ❌ Ads en calculator o remesas
- ❌ Cambiar colores/fuentes sin aprobación
- ❌ Inventar datos falsos (multiplicadores, % fake)
- ❌ Requests sin fallback a caché
