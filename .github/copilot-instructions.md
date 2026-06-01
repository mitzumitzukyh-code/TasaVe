# GitHub Copilot Instructions — TasaVe

## Proyecto
TasaVe es una app Flutter multiplataforma (Android + iOS + Web) para consultar la tasa de cambio BCV de Venezuela en tiempo real. Backend en Cloudflare Workers + KV.

- **URL de producción**: https://tasave-app.pages.dev/ (NUNCA cambiar este dominio)
- **Filosofía de diseño**: UI limpia, colores sólidos (rojo + blanco + negro), funciones simples sin sobrecarga visual

## Reglas de código
- **State management**: SOLO Riverpod (StateNotifierProvider, FutureProvider, FutureProvider.family). NUNCA usar Provider, Bloc o GetX.
- **HTTP**: Dio con interceptores
- **Storage**: SharedPreferences via `localStorageProvider`
- **Charts**: fl_chart
- **Fonts**: Google Fonts — DM Sans (sans-serif), Space Mono (monoespaciado)
- **Ads**: google_mobile_ads — SOLO en home_screen, NUNCA en calculator ni remesas

## Modelo de datos principal
```dart
class TasaModel {
  final double bcvUsd;       // BCV USD oficial
  final double usdtP2P;      // Binance P2P top 5
  final double? yadioRate;   // Yadio.io tasa libre
  final double? bcvEur;      // BCV EUR
  final double? bcvCop;      // BCV COP
  final double? bcvBrl;      // BCV BRL
  final DateTime timestamp;
  final bool isFromCache;
  final String? nextUpdateMessage;
}
```

## Paleta unificada
```dart
Color primary  = Color(0xFFE53935);  // Rojo TasaVe
Color bg       = Color(0xFFFFFFFF);  // Blanco fondo
Color text     = Color(0xFF1A1A1A);  // Casi negro
Color success  = Color(0xFF2E7D32);  // Verde (subidas)
Color error    = Color(0xFFC62828);  // Rojo (bajadas)
Color warning  = Color(0xFFF57C00);  // Ámbar
```

## Reglas absolutas
1. **NUNCA hardcodear** tasas, porcentajes o textos de datos. Todo viene del API.
2. **NUNCA inventar valores** — si no hay dato, mostrar "—" o "sin datos"
3. **Offline first** — cachear en SharedPreferences, mostrar caché si no hay red
4. **Accesibilidad** — textScaler 1.375x global, toggle en ajustes, persiste en SharedPreferences
5. **Colores fijos**: primary=#E53935, bg=#FFFFFF, text=#1A1A1A
6. **Fuentes fijas**: DM Sans (sans-serif), Space Mono (mono)
7. **Errores** siempre en español simple, nunca códigos técnicos
8. **Idioma**: UI y respuestas en español (Venezuela)
9. **Calculadora**: máscara de entrada financiera con punto decimal fijo. Los dígitos se desplazan de derecha a izquierda (ej. `5` → `0,05`; `100` → `1,00`). Conversión USD↔Bs instantánea y bidireccional.

## Providers clave
- `tasaProvider` — StateNotifierProvider<TasaNotifier, AsyncValue<TasaModel>>
- `historyProvider` — FutureProvider.family<List<TasaHistoryEntry>, int>
- `accessibilityProvider` — StateNotifierProvider<AccessibilityNotifier, bool>
- `shellTabProvider` — StateProvider<int>
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

## Respaldo Oficial de Version
- Version oficial de retorno: `respaldo/version-real-2026-05-26`
- Regla: ante errores o cambios no deseados, regresar a esta version de respaldo, no a snapshots antiguos.
- Comando recomendado:
  - `git checkout main`
  - `git reset --hard respaldo/version-real-2026-05-26`
  - `git clean -fd`
