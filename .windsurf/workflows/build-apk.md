---
description: Compilar APK de TasaVe para Android
---

## Pasos para build APK

// turbo
1. Verificar análisis limpio:
```
flutter analyze --no-fatal-infos
```

2. Build APK release:
```
flutter build apk --release
```

3. El APK estará en:
```
build/app/outputs/flutter-apk/app-release.apk
```

4. Para build split por ABI (más ligero):
```
flutter build apk --split-per-abi --release
```
Genera APKs separados para arm64-v8a, armeabi-v7a y x86_64.

**Nota**: Verificar que `android/app/build.gradle` tiene el signing config correcto para release.
