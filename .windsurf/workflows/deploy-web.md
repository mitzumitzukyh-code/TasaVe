---
description: Deploy de la app web TasaVe a Cloudflare Pages
---

## Pasos para deploy web

1. Verificar que no hay errores de análisis:
```
flutter analyze --no-fatal-infos
```
Debe terminar sin errors ni warnings (infos son aceptables).

// turbo
2. Compilar la app web en modo release:
```
flutter build web --release
```

3. Verificar que los archivos SEO están en el build:
- `build/web/robots.txt`
- `build/web/sitemap.xml`
- `build/web/index.html` debe contener `<noscript>`, `canonical`, `ld+json`

4. Deploy a Cloudflare Pages:
```
npx wrangler pages deploy build/web --project-name=tasave-app
```

5. Verificar la URL de deploy que devuelve wrangler (formato: `https://XXXXX.tasave-app.pages.dev`)

**Nota**: La URL de producción `https://tasave-app.pages.dev` se actualiza automáticamente.
