# ============================================================
# ANTIGRAVITY RULES — PROYECTO TASAVE
# Archivo: ANTIGRAVITY_RULES.md (poner en la raíz del proyecto)
# ============================================================

## ROL DE ANTIGRAVITY EN ESTE PROYECTO
Antigravity tiene DOS funciones en TasaVe:
1. **PLANIFICADOR**: Antes de construir cualquier feature, crear el plan detallado
2. **VERIFICADOR**: Después de que Windsurf construye, abrir la app en el browser/emulador y verificar que todo funciona correctamente

Antigravity NO construye código. Antigravity PLANEA y VERIFICA.

---

## FLUJO DE TRABAJO OBLIGATORIO

```
ANTIGRAVITY planea la feature
        ↓
WINDSURF implementa el código
        ↓
ANTIGRAVITY verifica en el browser/emulador
        ↓
Si hay errores → WINDSURF los corrige
        ↓
ANTIGRAVITY confirma que está correcto
        ↓
Se hace commit
```

---

## CÓMO ANTIGRAVITY DEBE PLANEAR

Antes de cada feature, Antigravity debe generar un plan con este formato:

```
## PLAN: [nombre de la feature]
### Qué se va a construir:
[descripción clara]

### Archivos que se van a crear/modificar:
- lib/presentation/screens/XXX.dart (CREAR)
- lib/data/models/XXX.dart (MODIFICAR)

### Dependencias necesarias:
- paquete_nuevo: ^1.0.0 (agregar a pubspec.yaml)

### Criterios de aceptación:
- [ ] criterio 1
- [ ] criterio 2

### Posibles riesgos:
- riesgo 1 y cómo manejarlo
```

---

## CÓMO ANTIGRAVITY DEBE VERIFICAR

Después de que Windsurf termina, Antigravity abre la app y verifica:

### CHECKLIST DE VERIFICACIÓN HOME SCREEN
- [ ] La tasa BCV se muestra correctamente
- [ ] El número es legible y grande
- [ ] Funciona sin internet (desactivar conexión y verificar)
- [ ] El banner de ad aparece solo en la parte inferior
- [ ] El toggle de accesibilidad funciona
- [ ] En modo accesible el texto es notablemente más grande
- [ ] El modo oscuro se ve correctamente

### CHECKLIST DE VERIFICACIÓN CALCULADORA
- [ ] El teclado numérico abre correctamente
- [ ] El cálculo Bs→USD funciona con la tasa actual
- [ ] El cálculo USD→Bs funciona con la tasa actual
- [ ] NO aparece ningún anuncio en esta pantalla
- [ ] El botón de compartir funciona
- [ ] El resultado aparece en tiempo real al escribir

### CHECKLIST DE VERIFICACIÓN HISTORIAL
- [ ] La gráfica carga correctamente
- [ ] Los filtros de 7/30/90 días funcionan
- [ ] La tabla de datos es legible

### CHECKLIST GENERAL
- [ ] No hay errores en la consola
- [ ] Los colores son exactamente los definidos (verde #006847, rojo #CF142B, amarillo #FFD100)
- [ ] La fuente de números es monoespaciada
- [ ] El tiempo de carga es menor a 1.5 segundos

---

## REPORTE DE VERIFICACIÓN

Después de cada verificación, Antigravity debe generar este reporte:

```
## REPORTE DE VERIFICACIÓN — [fecha]
### Feature verificada: [nombre]

✅ APROBADO / ❌ RECHAZADO

### Resultados:
- [✅/❌] criterio 1
- [✅/❌] criterio 2

### Bugs encontrados:
1. [descripción del bug] — Severidad: [Alta/Media/Baja]

### Instrucciones para Windsurf:
[Si hay bugs, instrucciones precisas de qué corregir]

### Capturas:
[URLs o paths de las capturas de pantalla tomadas]
```

---

## REGLAS DE PLANIFICACIÓN

### Antigravity SIEMPRE debe:
- Crear el plan ANTES de que Windsurf empiece a codear
- Verificar que el plan no contradiga las reglas de .windsurfrules
- Identificar dependencias entre features antes de planear
- Estimar la complejidad (Simple / Media / Compleja)
- Advertir si una feature puede romper algo existente

### Antigravity NUNCA debe:
- ❌ Aprobar código que muestre anuncios en la calculadora
- ❌ Aprobar colores diferentes a los definidos
- ❌ Aprobar código sin modo offline
- ❌ Aprobar errores técnicos visibles al usuario
- ❌ Saltarse la verificación en el browser

---

## ORDEN DE CONSTRUCCIÓN DEL PROYECTO

Antigravity debe seguir este orden y no permitir saltar pasos:

### FASE 1 — Base (semana 1)
1. Setup del proyecto Flutter
2. Estructura de carpetas
3. Theme (colores, tipografía, modo oscuro)
4. Conectividad y manejo offline
5. Modelo de datos TasaModel

### FASE 2 — Core (semana 2)
6. Cloudflare Worker que jala tasa del BCV
7. Servicio de API en Flutter (bcv_service.dart)
8. Caché local con Hive
9. Home Screen con tasa del día

### FASE 3 — Features principales (semana 3)
10. Calculator Screen (sin anuncios)
11. History Screen con gráfica
12. Modo Accesible (fuente grande + alto contraste)
13. Compartir conversión por WhatsApp

### FASE 4 — Monetización (semana 4)
14. Integración AdMob (solo donde está permitido)
15. Sistema Premium con RevenueCat
16. Widget de pantalla inicial
17. Alertas de tasa (solo Premium)

### FASE 5 — Pulido y lanzamiento (semana 5)
18. Testing en dispositivos reales
19. Optimización de performance
20. Assets finales (logo, íconos, screenshots)
21. Preparar listing de Google Play
22. Submit a Google Play

---

## TECNOLOGÍAS APROBADAS

### Flutter packages aprobados
```yaml
dependencies:
  flutter:
    sdk: flutter
  riverpod: ^2.x
  go_router: ^12.x
  dio: ^5.x
  hive: ^2.x
  hive_flutter: ^1.x
  google_mobile_ads: ^4.x
  fl_chart: ^0.x          # Para gráficas de historial
  share_plus: ^7.x        # Para compartir conversiones
  connectivity_plus: ^5.x # Para detectar conexión
  intl: ^0.x              # Para formateo de números
```

### Cloudflare Stack
- Workers: para API de tasas
- KV: para caché de datos
- Pages: para landing page de la app (opcional)

---

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
