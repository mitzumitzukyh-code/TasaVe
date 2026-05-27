# CLAUDE.md — CalculaYa Project Instructions

## Proyecto
CalculaYa — App Flutter multiplataforma (Android + iOS + Web) para consultar la tasa de cambio BCV de Venezuela en tiempo real. Backend en Cloudflare Workers + KV.

- **URL de producción**: https://tasave-app.pages.dev/
- **Filosofía de diseño**: Light UI limpia, colores Venezuela (verde/rojo/amarillo), funciones simples sin sobrecarga visual

## Idioma
Responder SIEMPRE en español (Venezuela). UI en español.

## Stack
- Flutter 3.x / Dart 3.x
- State management: SOLO Riverpod (StateNotifierProvider, FutureProvider, FutureProvider.family)
- HTTP: Dio | Storage: SharedPreferences | Charts: fl_chart
- Fonts (Google Fonts): DM Sans (cuerpo/títulos), Space Mono (números/tasas)
- Ads: google_mobile_ads — SOLO en home_screen
- Backend: Cloudflare Workers (Wrangler CLI)

## Comandos clave
- Analizar: `flutter analyze --no-fatal-infos`
- Build web: `flutter build web --release`
- Deploy web: `npx wrangler pages deploy build/web --project-name=tasave-app`
- Deploy backend: `cd backend && npx wrangler deploy`

## Modelo principal (simplificado)
```dart
class TasaModel {
  final double bcvUsd;      // BCV USD oficial
  final double usdtP2P;     // Binance P2P top 5
  final DateTime timestamp;
  final bool isFromCache;
}
```

## Constantes fiscales (lib/core/constants/app_constants.dart)
- IVA = 0.16 (16%)
- IGTF = 0.03 (3%)

## Paleta de colores (Light UI)
- bg: #F5F5F5 | surface: #FFFFFF | card: #FFFFFF
- green: #006847 (Venezuela) | red: #CF142B (Venezuela) | yellow: #FFD100
- text: #1A1A1A | text2: #757575 | text3: #9E9E9E

## Providers
- `tasaProvider` → StateNotifierProvider<TasaNotifier, AsyncValue<TasaModel>>
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
5. Colores fijos: green=#006847, red=#CF142B, yellow=#FFD100
6. Fuentes fijas: DM Sans, Space Mono
7. Errores en español simple
8. Ads SOLO en home_screen
9. SOLO Riverpod — nunca Provider/Bloc/GetX
10. Impuestos centralizados en app_constants.dart (IVA, IGTF)

## Prohibiciones
- ❌ Hardcodear tasas/spreads/porcentajes
- ❌ setState en pantallas principales
- ❌ Ads en calculator o remesas
- ❌ Cambiar colores/fuentes sin aprobación
- ❌ Inventar datos falsos
- ❌ Requests sin fallback a caché

## Version de Respaldo Oficial
- Version oficial de retorno: `respaldo/version-real-2026-05-26`
- Politica: si ocurre una regresion, volver SIEMPRE a esta version de respaldo y NO a versiones antiguas previas.
- Comando de retorno rapido:
  - `git checkout main`
  - `git reset --hard respaldo/version-real-2026-05-26`
  - `git clean -fd`
