---
description: Detectar y eliminar datos hardcodeados en la app TasaVe
---

## Pasos para auditar hardcodeo

1. Buscar multiplicadores falsos en las pantallas:
```
grep -rn "p2p \*\|p2pRate \*\|bcvRate \*" lib/presentation/screens/
```
Si encuentra `* 0.99`, `* 1.002` o similar → reemplazar con dato real del API.

2. Buscar porcentajes inventados:
```
grep -rn "% hoy\|% 99\|value \* 7" lib/presentation/screens/
```
Todo porcentaje debe calcularse: `((valor - bcvUsd) / bcvUsd * 100)`

3. Buscar callbacks vacíos:
```
grep -rn "onTap: () {}" lib/presentation/screens/
```
Todo botón debe tener acción real.

4. Buscar textos estáticos de datos:
```
grep -rn "Ritmo:\|inusual\|hace 2m\|09:22\|08:15" lib/presentation/screens/
```
Si encuentra textos estáticos de datos → deben venir del provider.

5. Verificar que TasaModel incluye yadioRate:
```
grep -n "yadioRate" lib/data/models/tasa_model.dart
```

6. Verificar que el backend tiene fetchYadioRate:
```
grep -n "fetchYadioRate\|yadio" backend/src/index.js
```

// turbo
7. Compilar y verificar:
```
flutter analyze --no-fatal-infos
```

**Regla**: NUNCA inventar datos. Si el API no tiene un valor, mostrar "—" o "sin datos".
