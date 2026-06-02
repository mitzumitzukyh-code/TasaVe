# TASAVE — PLAN DE IMPLEMENTACIÓN PARA DEEPSEEK + CLAUDE CODE
> Lee este archivo completo ANTES de escribir una sola línea de código.
> Sigue cada paso EN ORDEN. NO saltes pasos. NO inventes funciones.
> NO cambies colores. NO añadas dependencias no listadas.

---

## CONTEXTO DEL PROYECTO

App Flutter de tasas de cambio para Venezuela.
Stack: Flutter + Riverpod + Dio + Hive (offline-first).
Nombre del paquete en pubspec.yaml: `calculaya` — NO renombrar.
Carpeta raíz del proyecto: `C:\Users\pc\OneDrive\Desktop\App`

---

## PALETA DE COLORES — LEY ABSOLUTA

### Modo claro (light)
```dart
background:    #FFFFFF   // Fondo principal — BLANCO PURO
surfaceLight:  #F5F5F5   // Cards secundarias
textPrimary:   #1A1A1A   // Texto principal
textSecondary: #AAAAAA   // Texto secundario / labels
redLight:      #CC1C1C   // Acento: hero card, FAB, logo
greenResult:   #16A34A   // Verde resultado calculadora
borderLight:   rgba(0,0,0,0.08)
```

### Modo oscuro (dark)
```dart
background:    #0C0C0C   // Fondo OLED negro
surfaceDark:   #181818   // Cards
surfaceDark2:  #222222   // Cards hover / spread pills
textPrimary:   #F0F0F0   // Texto principal
textSecondary: #444444   // Texto secundario
redDark:       #FF3A3A   // Acento más brillante (necesario sobre negro)
greenResult:   #4ADE80   // Verde resultado calculadora
borderDark:    rgba(255,255,255,0.06)
```

**REGLA CRÍTICA — hero card:**
- Modo claro → hero card ROJA (#CC1C1C) con texto blanco
- Modo oscuro → hero card OSCURA (#181818) con número blanco y borde #252525

**REGLA CRÍTICA — logo:**
- "tasave" es rojo en AMBOS modos: #CC1C1C (light) / #FF3A3A (dark)

---

## TIPOGRAFÍA

```dart
heroRateSize:    36.0,  FontWeight.w500, monospace, letterSpacing: -2.0
heroDecSize:     18.0,  FontWeight.w400, monospace, opacity: 0.55 (light) / color #444 (dark)
spreadValue:     12.0,  FontWeight.w500, monospace
calcInput:       15.0,  FontWeight.w500, monospace
rateCardValue:   12.0,  FontWeight.w500, monospace
sectionLabel:     9.0,  letterSpacing: 0.5, UPPERCASE, textSecondary
logoText:        17.0,  FontWeight.w500, letterSpacing: -0.5
fabItemLabel:     8.0,  textSecondary
```

---

## ARQUITECTURA DE NAVEGACIÓN

**NO usar BottomNavigationBar.**
**NO usar TabBar fijo.**

Una sola pantalla principal: `HomeScreen`.
Acceso a pantallas secundarias SOLO mediante FAB radial.

```
HomeScreen (siempre en pantalla)
  └── ExpandableFab (bottomCenter)
        ├── HistorialScreen  → Navigator.push
        ├── ScannerScreen    → Navigator.push
        ├── AlertasScreen    → Navigator.push
        └── AjustesScreen    → Navigator.push
```

---

## ESTRUCTURA DE ARCHIVOS

```
lib/
├── main.dart                           modificar: agregar ThemeProvider + temas
├── app_constants.dart                  CREAR
├── theme/
│   ├── app_colors.dart                 CREAR
│   └── app_theme.dart                  CREAR
├── providers/
│   ├── theme_provider.dart             CREAR
│   ├── rates_provider.dart             modificar existente si existe
│   └── calculator_provider.dart        CREAR
├── screens/
│   ├── home_screen.dart                CREAR (reemplazar si existe)
│   ├── historial_screen.dart           CREAR
│   ├── scanner_screen.dart             CREAR
│   ├── alertas_screen.dart             CREAR
│   └── ajustes_screen.dart             CREAR
└── widgets/
    ├── expandable_fab.dart             CREAR
    ├── hero_rate_card.dart             CREAR
    ├── quick_calculator.dart           CREAR
    ├── rates_grid.dart                 CREAR
    └── rate_mini_card.dart             CREAR
```

---

## PASO 1 — app_colors.dart

Crear `lib/theme/app_colors.dart`:

```dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // LIGHT
  static const Color redLight      = Color(0xFFCC1C1C);
  static const Color bgLight       = Color(0xFFFFFFFF);
  static const Color surfaceLight  = Color(0xFFF5F5F5);
  static const Color textPrimL     = Color(0xFF1A1A1A);
  static const Color textSecL      = Color(0xFFAAAAAA);
  static const Color greenLight    = Color(0xFF16A34A);
  static const Color borderLight   = Color(0x14000000);

  // DARK
  static const Color redDark       = Color(0xFFFF3A3A);
  static const Color bgDark        = Color(0xFF0C0C0C);
  static const Color surfaceDark   = Color(0xFF181818);
  static const Color surfaceDark2  = Color(0xFF222222);
  static const Color surfaceDark3  = Color(0xFF252525);
  static const Color textPrimD     = Color(0xFFF0F0F0);
  static const Color textSecD      = Color(0xFF444444);
  static const Color greenDark     = Color(0xFF4ADE80);
  static const Color borderDark    = Color(0x0FFFFFFF);
}
```

---

## PASO 2 — app_theme.dart

Crear `lib/theme/app_theme.dart` con dos ThemeData:

```dart
// AppTheme.light → usa AppColors *Light
// AppTheme.dark  → usa AppColors *Dark

// Puntos obligatorios en AMBOS temas:
scaffoldBackgroundColor: bgLight / bgDark
colorScheme.primary:     redLight / redDark
cardColor:               surfaceLight / surfaceDark
appBarTheme:             backgroundColor transparent, elevation 0, centerTitle false
floatingActionButtonTheme: backgroundColor redLight/redDark, foreground white
useMaterial3: true
```

---

## PASO 3 — theme_provider.dart + main.dart

### theme_provider.dart
```dart
// StateNotifierProvider<ThemeNotifier, ThemeMode>
// Persiste en Hive: box 'settings', key 'themeMode'
// Valores: 'light' | 'dark' | 'system'
// Métodos: toggleTheme(), setTheme(ThemeMode)
// Default: ThemeMode.system
```

### main.dart — cambios:
```dart
MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: ref.watch(themeProvider),
  home: const HomeScreen(),
  debugShowCheckedModeBanner: false,
)
```

---

## PASO 4 — expandable_fab.dart

Specs EXACTAS del FAB radial:

```
Posición: FloatingActionButtonLocation.centerFloat

FAB principal:
  - Tamaño: 42×42px, circular
  - Color: redLight / redDark
  - Ícono: "+" que rota 45° cuando isOpen == true
  - Animación rotación: 250ms, Curves.easeOutBack

Menú expandido (visible cuando isOpen == true):
  - Aparece ENCIMA del FAB (posición absoluta, bottom: 52px)
  - Layout: Row horizontal, 4 FabItems
  - Fondo: bgLight / surfaceDark
  - Border-radius: 22px (pill)
  - Border: 0.5px borderLight / borderDark
  - Padding: 7px vertical, 10px horizontal
  - Gap entre items: 8px

Cada FabItem:
  - Ícono: círculo 32px, fondo surfaceLight / surfaceDark2, ícono 14px
  - Label debajo: 8sp, textSecL / textSecD, centrado, sin wrap
  - onTap: cerrar menú + Navigator.push a la pantalla

Items (en este orden):
  1. Icons.bar_chart_rounded     "Historial"  → HistorialScreen
  2. Icons.document_scanner      "Escanear"   → ScannerScreen
  3. Icons.notifications_none    "Alertas"    → AlertasScreen
  4. Icons.settings_outlined     "Ajustes"    → AjustesScreen

Barrier: cuando isOpen, GestureDetector transparente cubre toda la pantalla.
  Al tocar fuera del menú → cerrar (isOpen = false).
```

---

## PASO 5 — hero_rate_card.dart

```dart
// Props: double rate, double change, double buyRate, double sellRate

// MODO CLARO:
Container(
  margin: EdgeInsets.fromLTRB(10, 2, 10, 0),
  padding: EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: AppColors.redLight,           // ← ROJA en modo claro
    borderRadius: BorderRadius.circular(14),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Label "DÓLAR BCV": 9sp, white op 0.75, uppercase, letterSpacing 0.8
      // Número: "54" en 36sp w500 white monospace + ",23" en 18sp white op 0.55
      // Subtítulo: "Bs por 1 USD · ▲ X.XX%" 10sp white op 0.65
      // Spread row: 2 pills con bg rgba(255,255,255,0.18)
    ]
  )
)

// MODO OSCURO (mismo widget, distinto decoration):
decoration: BoxDecoration(
  color: AppColors.surfaceDark,          // ← OSCURA en modo oscuro
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: AppColors.surfaceDark3, width: 0.5),
)
// Label "DÓLAR BCV": color textSecD (#444)
// Número: color textPrimD (#F0F0F0)
// Decimales: color #444444
// Cambio %: color redDark si positivo, sin color diferente si negativo
// Spread pills: bg surfaceDark2, border borderDark

// Formato del número:
// rate = 54.23 → mostrar "54" + ",23"
// Separar entero y decimales con .split('.')
// SIEMPRE mostrar 2 decimales
// Formato venezolano: 1000+ → "1.543,00" (punto=miles, coma=dec)
```

---

## PASO 6 — quick_calculator.dart

```dart
// Widget con TextEditingController para input USD
// Resultado Bs = inputUSD * rateActual (desde rates_provider)

Container(
  margin: EdgeInsets.symmetric(horizontal: 10),
  padding: EdgeInsets.all(9) + horizontal 11,
  decoration: BoxDecoration(
    color: surfaceLight / surfaceDark,
    borderRadius: BorderRadius.circular(11),
    border: Border.all(color: borderLight/borderDark, width: 0.5),
  ),
  child: Column(
    children: [
      // Fila USD: label "USD" (10sp textSec) | TextField (15sp w500 mono textPrim)
      // Divider 0.5px
      // Fila Bs:  label "Bs"  (10sp textSec) | Text resultado (15sp w500 mono GREEN)
    ]
  )
)

// TextField: solo números y punto/coma, sin label, sin borde propio
// keyboardType: TextInputType.numberWithOptions(decimal: true)
// inputFormatters: solo dígitos y punto/coma
// Al cambiar USD → calcular Bs en tiempo real con onChanged
// Formato: venezolano siempre (5.423,00)
// Si input vacío → mostrar "0,00" en Bs
```

---

## PASO 7 — rate_mini_card.dart + rates_grid.dart

### rate_mini_card.dart
```dart
// Props: String name, String value, double? change, bool isDiscrete

// Si isDiscrete == true:
//   - Opacity: 0.55
//   - Badge "ref" junto al nombre: 7sp, bg surfaceLight2/surfaceDark2, color textSec
//   - change text: "P2P ref." en textSec (NO rojo/verde)

// Si isDiscrete == false:
//   - change > 0: "▲ X.XX%" greenResult
//   - change < 0: "▼ X.XX%" redLight/redDark
//   - change == null: sin indicador

Container(
  decoration: BoxDecoration(
    color: surfaceLight / surfaceDark,
    borderRadius: BorderRadius.circular(9),
    border: Border.all(color: borderDark, width: 0.5), // solo en dark
  ),
  padding: EdgeInsets.fromLTRB(9, 7, 9, 7),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // name: 9sp textSec
      // value: 12sp w500 mono textPrim
      // change: 9sp (ver lógica arriba)
    ]
  )
)
```

### rates_grid.dart
```dart
// GridView 2 columnas, gap 5px, padding 5px 10px
// shrinkWrap: true, physics: NeverScrollableScrollPhysics

// Monedas en orden FIJO e inmutable:
// [0] name:"EUR/BCV"  value: eurRate  isDiscrete: false
// [1] name:"COP"      value: copRate  isDiscrete: false
// [2] name:"USDT"     value: usdtRate isDiscrete: true    ← referencia semi-oculta
// [3] name:"BRL"      value: brlRate  isDiscrete: false
```

---

## PASO 8 — home_screen.dart

```dart
Scaffold(
  // SIN AppBar
  // SIN BottomNavigationBar
  body: SafeArea(
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP BAR (custom, no AppBar):
          //    Padding: fromLTRB(14,8,14,6)
          //    Row: logo "tasave" (izq) + "BCV · hace Xh" (der)
          //    logo: 17sp w500 letterSpacing -0.5 redLight/redDark
          //    timestamp: 10sp textSec

          // 2. HeroRateCard()

          // 3. SectionLabel("Calculadora rápida")
          //    Padding: fromLTRB(14,9,14,4), 9sp, uppercase, textSec

          // 4. QuickCalculator()

          // 5. SectionLabel("Otras monedas")

          // 6. RatesGrid()

          // 7. AdBanner (solo aquí, NUNCA en otras pantallas)
          //    Altura: 52px, fondo negro/surface, texto "Publicidad" 9sp gris
          //    AdMob BannerAd si está configurado, sino placeholder

          // 8. SizedBox(height: 80) ← espacio para el FAB
        ]
      )
    )
  ),
  floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
  floatingActionButton: const ExpandableFab(),
)
```

---

## PASO 9 — scanner_screen.dart

Agregar a pubspec.yaml (PREGUNTAR ANTES):
```yaml
google_mlkit_text_recognition: ^0.11.0
```

AndroidManifest.xml — agregar dentro de `<manifest>`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

Info.plist — agregar:
```xml
<key>NSCameraUsageDescription</key>
<string>TasaVe necesita la cámara para escanear precios en bolívares</string>
```

```dart
// Flujo de la pantalla:
// 1. Solicitar permiso de cámara con permission_handler
// 2. Si denegado → mostrar mensaje + botón "Ingresar manualmente"
// 3. Si concedido → iniciar CameraController
//
// Layout (Stack):
//   - CameraPreview (fondo completo)
//   - Overlay semitransparente negro (excepto zona del viewfinder)
//   - Viewfinder: cuadrado 160×160, centrado verticalmente en 45% pantalla
//       borde: 2px Color(0xFFCC1C1C), borderRadius 16
//       4 esquinas: L-shapes en blanco, 2px stroke, 20px largo
//       ScanLine: Container 140px wide, 1.5px alto, rojo, animación
//         AnimationController repeat, 1.8s, valor 0→1
//         top = lerp(0.15, 0.80) × 160 + viewfinderTop
//   - Texto instrucción: "Apunta al precio en Bs"
//       9sp, blanco op 0.7, letterSpacing 0.8, uppercase, encima del viewfinder
//   - Panel resultado (aparece cuando hay detección):
//       Posición: 70% de la altura de pantalla hacia abajo
//       Container: bg rgba(0,0,0,0.8), borderRadius 12, padding 10px 16px
//       "Precio detectado" label: 9sp gris
//       Precio Bs: 22sp w500 mono blanco
//       Conversión: "= X.XX USD · X.XX EUR" 13sp gris
//       2 botones: "Guardar" (bg #CC1C1C, blanco) + "Reescanear" (bg #222, gris)
//   - Botón manual (siempre visible abajo):
//       "Ingresar manualmente" → show TextField dialog

// Lógica OCR:
TextRecognizer recognizer = TextRecognizer();
// Procesar frame cada 1.5s (no en cada frame para no sobrecargar)
// Extraer números: RegExp(r'\d[\d.,]{2,}')
// Tomar el número mayor encontrado como precio probable
// Limpiar: reemplazar puntos de miles, coma decimal → double
// Convertir: precioUSD = precioBs / rateActual

// Guardar en Hive:
// box 'scans', lista de Map: {bs: double, usd: double, date: String}
// Máximo 50 entradas, FIFO
```

---

## PASO 10 — alertas_screen.dart

```dart
// Modelo Alerta (Hive HiveObject o simple Map):
// { tipo: 'above'|'below'|'daily', threshold: double?, activa: bool, id: String }

// Pantalla:
AppBar: título "Alertas", sin acciones

// Si lista vacía:
Center(
  child: Column(
    children: [
      Icon(Icons.notifications_none, size: 48, color: textSec),
      Text("Sin alertas configuradas", style: textSec 14sp),
      Text("Toca + para crear una", style: textSec 12sp),
    ]
  )
)

// Si hay alertas:
ListView de AlertCard:
  cada card: superficie card, borderRadius 10, padding 12px
  Row: Column(tipo/threshold) | Spacer | Switch(activa)
  tipo 'above': "Sube de Bs X,XX"
  tipo 'below': "Baja de Bs X,XX"
  tipo 'daily': "Publicación diaria BCV"

// FAB (bottomRight esta vez, es pantalla secundaria):
FloatingActionButton → showDialog nueva alerta

// Dialog nueva alerta:
AlertDialog con:
  SegmentedButton 3 opciones: "Sube de" / "Baja de" / "Publicación diaria"
  Si sube o baja → TextField numérico para umbral
  Botones: Cancelar | Crear alerta

// Persistencia: Hive box 'alerts'
// Notificaciones: si flutter_local_notifications está en pubspec → inicializar
//   sino → solo persistir, TODO comentado para fase 2
```

---

## PASO 11 — historial_screen.dart

```dart
AppBar: título "Historial", acciones: [IconButton export]

// Chips de filtro (días):
Row con 4 chips: "7D" | "30D" | "90D" | "1A"
Chip activo: bg redLight/redDark, texto blanco, borderRadius 20
Chip inactivo: bg surface, texto textSec, border borderLight/borderDark

// Gráfica:
// Si fl_chart está en pubspec → LineChart
// Sino → CustomPainter simple (línea + puntos)
// Alto: 160px
// Color línea: redLight/redDark, strokeWidth: 1.5
// Sin grid, sin ejes visibles
// Sin eje Y con etiquetas (solo la línea)
// Punto activo al tap: tooltip con fecha y valor

// 3 metric cards (Row, mainAxisAlignment: spaceEvenly):
// MIN / PROM / MAX del período
// Cada card: bg surface, borderRadius 8, padding 12
// label 9sp textSec + valor 16sp w500 mono

// Lista de entradas (debajo de gráfica):
ListView.separated con filas:
  [fecha 12sp textSec] [Spacer] [valor 13sp w500 mono] [±%% 11sp verde/rojo]
  separator: Divider 0.5px

// Botón exportar (AppBar action):
// Generar imagen con fl_chart screenshot o share_plus
// Si no hay paquete → mostrar SnackBar "Función próximamente"
```

---

## PASO 12 — ajustes_screen.dart

```dart
AppBar: título "Ajustes"

// Sección 1 — TasaVe Pro (SIEMPRE primera sección, destacada):
Container con border 1px redLight/redDark, borderRadius 12, margin 12px
  Row: Column(título + subtítulo) | Spacer | precio
  título: "TasaVe Pro" 15sp w500
  subtítulo: "Widgets, alertas y lista de precios. Pago único." 12sp textSec
  precio: "Bs 110 · $2.99" 11sp textSec
  ElevatedButton: "Obtener Pro"
    style: bg redLight/redDark, texto blanco, borderRadius 8
    onPressed: () { /* TODO: in_app_purchase */ }

// Sección 2 — Apariencia:
ListTile: "Modo" | leading ícono | trailing: DropdownButton o Switch
  Si Switch: conectar a ref.read(themeProvider.notifier).toggleTheme()
  Opción preferida: 3-way SegmentedButton: "Claro" | "Sistema" | "Oscuro"

// Sección 3 — Fuentes de datos (informativo, no interactivo):
ListTile: "Tasa BCV oficial" + subtítulo "Banco Central de Venezuela"
ListTile: "USDT P2P" + subtítulo "Referencia estadística Binance P2P"
ListTile: subtítulo "TasaVe no fija ni recomienda tasas de cambio" (disclaimer)

// Sección 4 — Acerca de:
ListTile: "Versión" + trailing Text(packageInfo.version)
ListTile: "Política de privacidad" → placeholder URL
ListTile: "Compartir app" → share_plus si disponible
```

---

## REGLAS ABSOLUTAS PARA DEEPSEEK

```
1. NO cambiar ningún hex de color — usar EXACTAMENTE los de este documento
2. NO usar BottomNavigationBar — SOLO FAB radial en HomeScreen
3. NO poner anuncios en pantallas secundarias — banner SOLO en HomeScreen
4. NO usar la palabra "paralelo" ni "negro" en ningún String del código
5. NO inventar endpoints de API — solo BCV oficial y Binance P2P público
6. NO añadir dependencias sin consultar al usuario primero
7. Formato numérico venezolano: punto=miles, coma=decimales (5.423,00)
8. El FAB principal va en FloatingActionButtonLocation.centerFloat
9. Implementar en el orden de pasos (cada paso depende del anterior)
10. Ejecutar "flutter analyze" después de cada paso y corregir errores
```

---

## DISCLAIMER LEGAL — incluir en AjustesScreen y primer onboarding

```
"Las tasas mostradas por TasaVe son de referencia informativa exclusivamente.
La tasa oficial del BCV es publicada por el Banco Central de Venezuela.
La referencia USDT P2P es una estadística de mercado descentralizado y no
representa ninguna tasa oficial. TasaVe no fija, aconseja ni recomienda
tasas de cambio para ninguna transacción."
```

---

## ORDEN RECOMENDADO DE SESIONES EN CLAUDE CODE

```bash
# Sesión 1 — Base de colores y tema
Lee TASAVE_DEEPSEEK_PLAN.md. Implementa Pasos 1, 2 y 3.
Ejecuta flutter analyze al final.

# Sesión 2 — Navegación
Lee TASAVE_DEEPSEEK_PLAN.md sección Paso 4.
Crea solo lib/widgets/expandable_fab.dart.
No modifiques otros archivos. flutter analyze.

# Sesión 3 — Widgets del home
Lee TASAVE_DEEPSEEK_PLAN.md Pasos 5, 6 y 7.
Crea hero_rate_card.dart, quick_calculator.dart, rate_mini_card.dart, rates_grid.dart.
flutter analyze.

# Sesión 4 — HomeScreen
Lee TASAVE_DEEPSEEK_PLAN.md Paso 8.
Crea/reemplaza home_screen.dart integrando todos los widgets.
flutter run para verificar visualmente.

# Sesión 5 — Scanner OCR
Lee TASAVE_DEEPSEEK_PLAN.md Paso 9.
ANTES de crear el archivo: pregunta si puedes agregar google_mlkit_text_recognition.
Si sí → agregar a pubspec.yaml, flutter pub get, luego crear scanner_screen.dart.

# Sesión 6 — Pantallas secundarias
Lee TASAVE_DEEPSEEK_PLAN.md Pasos 10 y 11.
Crea alertas_screen.dart y historial_screen.dart.
flutter analyze.

# Sesión 7 — Ajustes y pulido
Lee TASAVE_DEEPSEEK_PLAN.md Paso 12.
Crea ajustes_screen.dart.
Revisión final: flutter analyze + flutter test (si hay tests).
```

---

*TasaVe v1.0 — Plan generado en Junio 2026*
*Desarrollado con Claude Sonnet 4.6 + DeepSeek V4 Pro via Claude Code*
