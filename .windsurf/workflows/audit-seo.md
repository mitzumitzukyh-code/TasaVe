---
description: Auditoría SEO de la app web TasaVe
---

## Pasos para auditoría SEO

1. Verificar archivos SEO en `web/`:
   - `web/robots.txt` — debe existir con `Allow: /` y referencia a sitemap
   - `web/sitemap.xml` — debe tener la URL canónica
   - `web/manifest.json` — debe tener name, description, icons, categories

2. Verificar `web/index.html` contiene:
   - `<html lang="es">`
   - `<meta name="description">`
   - `<meta name="robots" content="index, follow">`
   - `<link rel="canonical">`
   - `<meta property="og:title">` y `og:description`, `og:image`
   - `<meta name="twitter:card">`
   - `<script type="application/ld+json">` (structured data)
   - `<link rel="preconnect">` al API
   - `<noscript>` con contenido HTML para crawlers

// turbo
3. Build web y verificar que archivos se copian al build:
```
flutter build web --release
```

4. Verificar archivos en build:
```
dir build\web\robots.txt
dir build\web\sitemap.xml
```

**Nota**: El `<noscript>` es CRÍTICO para Flutter web porque todo el contenido se renderiza en JS/Canvas. Sin noscript, los bots de Google ven una página vacía.
