# ANTIGRAVITY RULES — PROYECTO TASAVE

## Rol de Antigravity
Antigravity tiene DOS funciones en TasaVe:
1. **PLANIFICADOR**: Antes de construir cualquier feature, crear el plan detallado
2. **VERIFICADOR**: Después de la implementación, abrir la app y verificar que todo funciona

Antigravity NO construye código. Antigravity PLANEA y VERIFICA.

---

## Flujo de trabajo obligatorio

```
ANTIGRAVITY planea la feature
        ↓
Coding Agent implementa el código
        ↓
ANTIGRAVITY verifica en browser/emulador
        ↓
Si hay errores → Coding Agent corrige
        ↓
ANTIGRAVITY confirma → commit
```

---

## Cómo planear

Antes de cada feature, generar un plan con este formato:

```
## PLAN: [nombre]
### Qué construir:
[descripción]

### Archivos a crear/modificar:
- lib/... (CREAR)
- lib/... (MODIFICAR)

### Dependencias:
- paquete: ^x.y.z

### Criterios de aceptación:
- [ ] criterio 1

### Riesgos:
- riesgo y mitigación
```

---

## Cómo verificar

### Home Screen
- [ ] Tasa BCV se muestra correctamente
- [ ] Número grande y legible
- [ ] Funciona sin internet (desconectar y probar)
- [ ] Banner de ad solo en parte inferior
- [ ] Toggle de accesibilidad funciona
- [ ] Texto crece visiblemente en modo accesible

### Calculadora
- [ ] Cálculo Bs→USD funciona con tasa actual
- [ ] Cálculo USD→Bs funciona con tasa actual
- [ ] NO hay anuncios
- [ ] Compartir funciona
- [ ] Resultado en tiempo real

### Historial
- [ ] Gráfica carga correctamente
- [ ] Filtros 7/30/90 días funcionan
- [ ] Tabla de datos legible

### General
- [ ] Sin errores en consola
- [ ] Colores exactos: primary=#E53935, bg=#FFFFFF, text=#1A1A1A
- [ ] Monospace en números (Space Mono)
- [ ] Carga < 1.5 segundos

---

## Reporte de verificación

```
## REPORTE — [fecha]
### Feature: [nombre]
✅ APROBADO / ❌ RECHAZADO

### Resultados:
- [✅/❌] criterio 1

### Bugs:
1. [descripción] — Severidad: Alta/Media/Baja

### Instrucciones:
[qué corregir]
```

---

## Reglas de planificación

### Siempre:
- Planear ANTES de codear
- Verificar que el plan no contradiga las reglas
- Identificar dependencias entre features
- Estimar complejidad (Simple / Media / Compleja)
- Advertir si algo puede romperse

### Nunca:
- ❌ Aprobar ads en calculadora
- ❌ Aprobar colores incorrectos
- ❌ Aprobar código sin offline first
- ❌ Aprobar errores técnicos visibles al usuario
- ❌ Saltarse verificación

---

## Stack tecnológico aprobado

| Capa        | Tecnología                              |
|-------------|-----------------------------------------|
| Frontend    | Flutter 3.x / Dart 3.x                  |
| Estado      | Riverpod (StateNotifier, FutureProvider) |
| HTTP        | Dio                                     |
| Storage     | SharedPreferences                       |
| Charts      | fl_chart                                |
| Tipografía  | DM Sans, Space Mono (Google Fonts)      |
| Ads         | google_mobile_ads                       |
| Backend     | Cloudflare Workers + KV                 |
| Push        | Web Push API (VAPID)                    |

### Dependencias Flutter
```yaml
dependencies:
  flutter_riverpod: ^2.x
  dio: ^5.x
  shared_preferences: ^2.x
  google_fonts: ^6.x
  fl_chart: ^0.x
  google_mobile_ads: ^5.x
  share_plus: ^7.x
  connectivity_plus: ^6.x
  intl: ^0.x
  url_launcher: ^6.x
  in_app_purchase: ^3.x
```

---

## API Endpoints

| Endpoint                    | Descripción              |
|-----------------------------|--------------------------|
| `GET /tasa`                 | Tasa actual + nextUpdate |
| `GET /tasa/history?days=N`  | Historial N días         |
| `GET /health`               | Health check             |
| `POST /alerts/register`     | Registrar alerta         |
| `GET /push/vapid-key`       | VAPID public key         |
| `POST /push/subscribe`      | Subscribir push          |
| `POST /push/unsubscribe`    | Desuscribir push         |

---

## Paleta de colores (inmutable)

```dart
Color primary    = Color(0xFFE53935);  // Rojo TasaVe
Color primaryDrk = Color(0xFFC62828);  // Rojo oscuro
Color bg         = Color(0xFFFFFFFF);  // Blanco fondo
Color surface    = Color(0xFFF5F5F5);  // Gris claro
Color text       = Color(0xFF1A1A1A);  // Casi negro
Color success    = Color(0xFF2E7D32);  // Verde
Color error      = Color(0xFFC62828);  // Rojo
Color warning    = Color(0xFFF57C00);  // Ámbar
```

---

## Constantes fiscales
- IVA = 0.16 (16%) · IGTF = 0.03 (3%)
- Definidas en `lib/core/constants/app_constants.dart`

---

## Versión de respaldo
- Rama: `respaldo/version-real-2026-05-26`
- Ante regresión: volver SIEMPRE a esta versión

## COMUNICACIÓN ENTRE IDEs

Cuando Antigravity encuentra un bug, debe comunicárselo a Windsurf así:

```
🐛 BUG ENCONTRADO
Severidad: [Alta/Media/Baja]
Pantalla: [nombre de la pantalla]
Descripción: [qué está mal]
Pasos para reproducir:
1. paso 1
2. paso 2
Comportamiento esperado: [qué debería pasar]
Comportamiento actual: [qué está pasando]
Archivo probable: [lib/presentation/screens/XXX.dart]
```
