# Playfit iOS — Design System & UI Kit Mapping

Este documento define la traducción semántica del sistema de diseño (UI Kit) y componentes del producto web hacia el entorno nativo de SwiftUI en iOS, adoptando las guías de diseño de Apple (HIG) y detallando las configuraciones de red y OAuth de Supabase.

---

## 1. Mapeo de Variables y Tokens Visuales

### A. Paleta de Colores
En SwiftUI, no se deben usar colores planos genéricos. Definiremos una extensión de `Color` que traduzca las variables CSS de Next.js (`Tailwind v4`) a colores dinámicos con soporte nativo de Light/Dark Mode en iOS:

| Token CSS Web | Color Hex (Light / Dark) | SwiftUI Asset Name / Código | Uso del Token |
| :--- | :--- | :--- | :--- |
| `--background` | `#f8fafc` / `#070a12` | `Color.playfitBackground` (ya implementado en `Colors.swift`) | Fondo general de las pantallas y vistas de lista. |
| `--foreground` | `#17201d` / `#f8fafc` | `Color.playfitForeground` | Texto principal, títulos e iconos decorativos. |
| `--card` | `#ffffff` opaco (light) / `rgba(15,23,42,0.76)` semi-transparente (dark) | `.thinMaterial` / `.ultraThinMaterial` | Fondo de contenedores e información flotante. Light mode es opaco en la web; el material translúcido nativo es una adaptación intencional, no una réplica 1:1. |
| `--accent` | `#0f766e` / `#ff6a3d` | `Color("playfitAccent")` | **Solo Interactividad:** Botones, interruptores, chips y estados activos. |
| `--ink` | `#0d9488` / `#38bdf8` | `Color("playfitInk")` | **Solo Datos/Métricas:** Confidence scores, porcentajes y gráficos. |
| `--positive` | `#047857` / `#34d399` | `Color.green` | Badges de coincidencia fuerte y estados de éxito. |
| `--warning` | `#b45309` / `#fbbf24` | `Color.orange` o `Color.yellow` | Advertencias moderadas, wishlist, y carga intermedia. |
| `--negative` | `#be123c` / `#fb7185` | `Color.red` | Alertas críticas, watch-outs de juegos, y bloqueos. |
| `--border` | Opacidad baja | `Color.primary.opacity(0.15)` | Bordes sutiles de separación para tarjetas de cristal. |

---

### B. Tipografía
Reemplazaremos las fuentes web (*Geist*) por la fuente del sistema de Apple (*San Francisco*) para asegurar una correcta legibilidad y soporte automático de Dynamic Type (escalado de fuentes por accesibilidad):

| Estilo Web | Atributos CSS | SwiftUI `Font` Equivalente |
| :--- | :--- | :--- |
| **H1 / Display** | `font-display text-4xl font-black` | `.font(.system(.largeTitle, design: .rounded)).weight(.heavy)` |
| **H2 / Section** | `font-display text-3xl font-extrabold` | `.font(.system(.title, design: .rounded)).bold()` |
| **Card Title** | `font-display text-xl font-semibold` | `.font(.system(.headline, design: .default))` |
| **Body** | `text-base leading-7` | `.font(.body)` |
| **Body Small** | `text-sm leading-6 text-muted` | `.font(.subheadline).foregroundColor(.secondary)` |
| **Mono / Metric** | `font-mono text-sm` | `.font(.system(.subheadline, design: .monospaced))` |
| **Eyebrow / Label** | `text-xs font-bold uppercase` | `.font(.system(.caption, design: .sans-serif)).bold()` |

---

### C. Iconografía
Lucide Icons se reemplaza por **SF Symbols** de Apple para mantener coherencia nativa con el sistema operativo:

* 🧭 `Compass` $\rightarrow$ `safari.fill` o `compass.drawing`
* 🧠 `Brain` $\rightarrow$ `brain.head.profile` o `brain`
* 🎮 `Gamepad2` $\rightarrow$ `gamecontroller.fill`
* ✨ `Sparkles` $\rightarrow$ `sparkles`
* 💖 `Heart` $\rightarrow$ `heart.fill`
* ⚠️ `AlertCircle` $\rightarrow$ `exclamationmark.triangle.fill`
* 🔄 `RefreshCcw` $\rightarrow$ `arrow.clockwise`

---

## 2. Traducción de Componentes del Producto a SwiftUI (Estilo HIG Apple)

Para que los componentes del producto se sientan nativos y mantengan la estética de la app, adaptaremos su diseño de la siguiente manera:

### A. La Tarjeta Estrella (Hero Recommendation Card)
* **Web:** Es una tarjeta con un fondo translúcido semi-opaco y efectos de borde difuminados mediante Tailwind.
* **iOS (Liquid Glass HIG):**
  * Usar `.background(.ultraThinMaterial)` para que tome el color de fondo dinámicamente.
  * Añadir un borde sutil blanco o gris muy claro (`Color.white.opacity(0.15)`) con un grosor de `0.5` pt.
  * Implementar gestos nativos: Swipe horizontal para rotar la recomendación rápidamente, o un toque largo (Haptic Context Menu) para disparar opciones de calificación sin abrir el juego.

### B. Chips de Selección (Toggle Chips / Platforms)
* **Web:** Botones interactivos con hover y cambios de fondo de color planos.
* **iOS (HIG):**
  * Botones tipo pastilla (`Capsule`) usando `.background(isSelected ? Color("playfitAccent") : Color.secondary.opacity(0.2))`.
  * Animación suave en SwiftUI (`withAnimation(.spring())`) al cambiar su estado de selección.

### C. Arte de Portada (Cover Art Component)
* **Web:** Imagen responsiva con relación de aspecto fija y bordes redondeados.
* **iOS (HIG):**
  * Implementar un contenedor con una relación de aspecto de afiche típica (`.aspectRatio(3/4, contentMode: .fit)`).
  * Esquinas redondeadas suaves (`.cornerRadius(12)`).
  * Mostrar un placeholder elegante con un degradado en escala de grises y un icono de mando de consola (`gamecontroller.fill`) en el centro mientras la portada carga de forma asíncrona (`AsyncImage`).

### D. Dossier de Detalles del Juego
Ver `play-route-mapping.md` para el mapeo de ruta (`/game/[gameId]` → `GameDetailView.swift`) y el
contrato de producto de esa pantalla. Este documento solo cubre la traducción visual: presentar
mediante un **Sheet nativo** (`.sheet(isPresented:)`) o transición dentro de un `NavigationStack`,
con la cabecera colapsándose elegantemente al hacer scroll hacia arriba.

---

## 3. URLs y Entornos de Conexión (Supabase & Google Auth)

La app nativa ya tiene conexión directa con el backend y autenticación implementadas (`PlayfitAPI`, `PlayfitStorage`, ver `architecture.md`); se detallan las URLs del sistema para cada entorno:

### A. Entorno de Desarrollo (Local)
* **Next.js Web / API Local:** `http://127.0.0.1:3000`
  * Las peticiones de la app de iOS hacia el backend para obtener perfiles y recomendaciones de prueba deben apuntar a este endpoint local (ej: `http://127.0.0.1:3000/api/recommendations/today`).
* **Supabase Local (CLI):** `http://127.0.0.1:54321`
  * Las APIs locales de Supabase (Auth, REST y Functions) se levantan en este puerto.
* **Google OAuth Redirect URL (Local):** `http://127.0.0.1:3000/auth/callback`
  * Flujo web de retorno local tras loguearse con Google.

### B. Entorno de Producción
* **Next.js Web / API Producción:** `https://playfit-gold.vercel.app`
  * Endpoint productivo de la API de Playfit (ej: `https://playfit-gold.vercel.app/api/profile`).
* **Supabase Producción:** Configurado dinámicamente en el backend en Vercel conectado con el proyecto Cloud de Supabase (Región AWS `us-east-1`).

### C. Configuración del Login de Google en iOS (OAuth & Deep Links)
Para habilitar el inicio de sesión nativo de Google o mediante Supabase Auth en la aplicación de iOS, se deben contemplar estas especificaciones:

1. **Esquema de URL Personalizado (URL Scheme):**
   * En el panel de configuración de Xcode (`Info.plist`), registrar un URL Scheme único para la aplicación, por ejemplo: `playfit` o `com.playfit.app`.
2. **Redirect URL Registrada en Supabase:**
   * En la consola de Supabase (tanto local en `config.toml` como en producción), se debe añadir la URI de redirección nativa en la lista de URLs permitidas de autenticación (Redirect URLs):
     ```text
     playfit://auth/callback
     ```
3. **Flujo de Autenticación de SwiftUI:**
   * Al invocar la autenticación OAuth con el proveedor `"google"`, el cliente SDK de Supabase para Swift debe enviar la solicitud de redirección apuntando a la URL nativa:
     ```swift
     let url = supabase.auth.getOAuthSignInUrl(
         provider: "google",
         redirectTo: URL(string: "playfit://auth/callback")
     )
     ```
   * Utilizar `ASWebAuthenticationSession` para capturar de forma segura la redirección dentro de la app nativa y completar la sesión del usuario de forma transparente.
