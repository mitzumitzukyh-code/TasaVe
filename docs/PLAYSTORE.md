# TasaVe — Guía de publicación en Google Play

## 1. Payoneer (antes de Play Console)

1. Crear cuenta en [payoneer.com](https://payoneer.com) con cédula venezolana.
2. Obtener cuenta bancaria USD (EE.UU.) virtual.
3. Usar esa cuenta en Play Console → Pagos → **vínculo permanente**.

## 2. Play Console ($25 USD único)

1. [play.google.com/console](https://play.google.com/console) → Crear cuenta de desarrollador.
2. Pagar $25 (tarjeta internacional, ej. Zinli).
3. Vincular cuenta Payoneer para recibir pagos.

## 3. Producto suscripción Pro

En Play Console → **Monetización → Suscripciones**:

| Campo | Valor |
|-------|--------|
| ID del producto | `tasave_pro_monthly` |
| Precio | $1.99 USD / mes |
| Nombre | TasaVe Pro |

Debe coincidir con `SubscriptionConstants.proMonthlyId` en la app.

## 4. Política de privacidad (obligatorio)

URL pública (incluida en la app):

**https://tasave-app.pages.dev/privacy.html**

Desplegar web:

```bash
flutter build web --release
# Copiar web/privacy.html a build/web/privacy.html si no está incluido
npx wrangler pages deploy build/web --project-name=tasave-app
```

## 5. Generar AAB firmado (producción)

```bash
# Crear keystore (una sola vez — guardar copia segura)
keytool -genkey -v -keystore tasave-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias tasave

flutter build appbundle --release
```

Configurar firma en `android/key.properties` y `build.gradle.kts` antes de producción.

APK de prueba (debug signing):

```bash
flutter build apk --release
```

Salida: `build/app/outputs/apk/release/app-release.apk`

## 6. Play Console — checklist

- [ ] Título y descripción (corta + larga)
- [ ] 8 capturas de pantalla mínimo
- [ ] Ícono 512×512
- [ ] Feature graphic 1024×500
- [ ] Política de privacidad URL
- [ ] Seguridad de datos: cámara, AdMob, facturación
- [ ] Clasificación de contenido (cuestionario)
- [ ] targetSdk 36 (Android 14+)

## 7. Prueba interna

1. Subir AAB a **Prueba interna**.
2. Agregar 5 testers por correo.
3. Validar: tasas, calculadora, suscripción Pro.
4. Promover a producción.

## 8. Flujo de pagos (Venezuela)

Google Play (−30%) → Payoneer (−~2% retiro) → Zinli / USDT / Bs según prefieras.

Neto aproximado por suscripción $1.99: **~$1.36 USD**.
