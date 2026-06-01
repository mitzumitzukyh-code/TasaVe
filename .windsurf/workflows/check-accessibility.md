---
description: Verificar que el modo accesible funciona correctamente en TasaVe
---

## Pasos para verificar accesibilidad

1. Verificar que main.dart es ConsumerWidget y aplica textScaler:
```
grep -n "textScaler\|accessibilityProvider" lib/main.dart
```
Debe tener `ref.watch(accessibilityProvider)` y `TextScaler.linear(scale)` en `MaterialApp.builder`.

2. Verificar que el toggle en ajustes lee del provider correctamente:
```
grep -n "accessibilityProvider" lib/presentation/
```
El toggle debe usar `ref.read(accessibilityProvider.notifier)`.

3. Verificar que el provider persiste en SharedPreferences:
```
grep -n "setAccessibleMode\|isAccessibleMode" lib/data/cache/local_storage.dart
```

4. Verificar constantes de escala:
```
grep -n "ACCESSIBLE_FONT_SCALE\|MIN_TOUCH_TARGET" lib/utils/accessibility.dart
```
- NORMAL_FONT_SCALE = 1.0
- ACCESSIBLE_FONT_SCALE = 1.375
- MIN_TOUCH_TARGET = 48.0

5. Compilar:
```
flutter analyze --no-fatal-infos
```

**Regla**: El modo accesible NUNCA debe dejar de funcionar.
