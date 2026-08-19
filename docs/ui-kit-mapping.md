# Playfit iOS — Design System & UI Kit Mapping

This document defines the semantic mapping of the design system (UI Kit) and web product components
to the native SwiftUI environment on iOS. It follows Apple's Human Interface Guidelines (HIG) and
details Supabase networking and OAuth configuration.

---

## 1. Variables and Visual Token Mapping

### A. Color Palette
SwiftUI should not use generic flat colors. We define a `Color` extension that maps Next.js CSS
variables (`Tailwind v4`) to dynamic colors with native Light/Dark Mode support on iOS:

| Web CSS Token | Color Hex (Light / Dark) | SwiftUI Asset Name / Code | Token Usage |
| :--- | :--- | :--- | :--- |
| `--background` | `#f8fafc` / `#070a12` | `Color.playfitBackground` (already implemented in `Colors.swift`) | General background for screens and list views. |
| `--foreground` | `#17201d` / `#f8fafc` | `Color.playfitForeground` | Primary text, titles, and decorative icons. |
| `--card` | Opaque `#ffffff` (light) / semi-transparent `rgba(15,23,42,0.76)` (dark) | `.thinMaterial` / `.ultraThinMaterial` | Container and floating-information background. Light mode is opaque on web; native translucent material is an intentional adaptation, not a 1:1 replica. |
| `--accent` | `#0f766e` / `#ff6a3d` | `Color("playfitAccent")` | **Interaction only:** buttons, toggles, chips, and active states. |
| `--ink` | `#0d9488` / `#38bdf8` | `Color("playfitInk")` | **Data/metrics only:** confidence scores, percentages, and charts. |
| `--positive` | `#047857` / `#34d399` | `Color.green` | Strong-match badges and success states. |
| `--warning` | `#b45309` / `#fbbf24` | `Color.orange` or `Color.yellow` | Moderate warnings, wishlist, and intermediate loading. |
| `--negative` | `#be123c` / `#fb7185` | `Color.red` | Critical alerts, game watch-outs, and blockers. |
| `--border` | Low opacity | `Color.primary.opacity(0.15)` | Subtle separation borders for glass cards. |

---

### B. Typography
We replace the web (*Geist*) fonts with Apple's system font (*San Francisco*) to ensure readability
and automatic Dynamic Type support (accessibility font scaling):

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

### C. Iconography
Lucide Icons se reemplaza por **SF Symbols** de Apple para mantener coherencia nativa con el sistema operativo:

* 🧭 `Compass` $\rightarrow$ `safari.fill` o `compass.drawing`
* 🧠 `Brain` $\rightarrow$ `brain.head.profile` o `brain`
* 🎮 `Gamepad2` $\rightarrow$ `gamecontroller.fill`
* ✨ `Sparkles` $\rightarrow$ `sparkles`
* 💖 `Heart` $\rightarrow$ `heart.fill`
* ⚠️ `AlertCircle` $\rightarrow$ `exclamationmark.triangle.fill`
* 🔄 `RefreshCcw` $\rightarrow$ `arrow.clockwise`

---

## 2. Mapping Product Components to SwiftUI (Apple HIG Style)

To make product components feel native while preserving the app's visual language, adapt them as follows:

### A. Hero Recommendation Card
* **Web:** A card with a semi-opaque translucent background and blurred border effects through Tailwind.
* **iOS (Liquid Glass HIG):**
  * Use `.background(.ultraThinMaterial)` so the background color updates dynamically.
  * Add a subtle white or light-gray border (`Color.white.opacity(0.15)`) with a `0.5` pt width.
  * Implement native gestures: horizontal swipe to rotate the recommendation quickly, or a long press
    (Haptic Context Menu) to expose rating options without opening the game.

### B. Selection Chips (Toggle Chips / Platforms)
* **Web:** Interactive buttons with hover states and flat background-color changes.
* **iOS (HIG):**
  * Use pill-shaped (`Capsule`) buttons with `.background(isSelected ? Color("playfitAccent") : Color.secondary.opacity(0.2))`.
  * Use a smooth SwiftUI animation (`withAnimation(.spring())`) when selection changes.

### C. Cover Art Component
* **Web:** Responsive image with a fixed aspect ratio and rounded corners.
* **iOS (HIG):**
  * Use a container with a typical poster aspect ratio (`.aspectRatio(3/4, contentMode: .fit)`).
  * Use soft rounded corners (`.cornerRadius(12)`).
  * Show an elegant grayscale-gradient placeholder with a game-controller icon (`gamecontroller.fill`)
    centered while the cover loads asynchronously (`AsyncImage`).

### D. Game Details Dossier
See `play-route-mapping.md` for the route mapping (`/game/[gameId]` → `GameDetailView.swift`) and
that screen's product contract. This document covers visual mapping only: present it with a native
**Sheet** (`.sheet(isPresented:)`) or a transition inside a `NavigationStack`, with the header
collapsing elegantly as the user scrolls up.

---

## 3. URLs and Connection Environments (Supabase & Google Auth)

The native app already has direct backend connectivity and authentication implemented (`PlayfitAPI`,
`PlayfitStorage`; see `architecture.md`). The system URLs for each environment are listed below:

### A. Development Environment (Local)
* **Local Next.js Web / API:** `http://127.0.0.1:3000`
  * iOS requests to the backend for test profiles and recommendations must target this local endpoint (for example, `http://127.0.0.1:3000/api/recommendations/today`).
* **Local Supabase (CLI):** `http://127.0.0.1:54321`
  * Local Supabase APIs (Auth, REST, and Functions) run on this port.
* **Google OAuth Redirect URL (Local):** `http://127.0.0.1:3000/auth/callback`
  * Local web return flow after signing in with Google.

### B. Production Environment
* **Production Next.js Web / API:** `https://playfit-gold.vercel.app`
  * Production Playfit API endpoint (for example, `https://playfit-gold.vercel.app/api/profile`).
* **Production Supabase:** Configured dynamically in the Vercel backend connected to the Supabase Cloud project (AWS region `us-east-1`).

### C. Google Sign-In Configuration on iOS (OAuth & Deep Links)
To enable native Google sign-in or Supabase Auth sign-in in the iOS app, follow these specifications:

1. **Custom URL Scheme:**
   * In Xcode's configuration panel (`Info.plist`), register a unique URL Scheme for the app, such as `playfit` or `com.playfit.app`.
2. **Redirect URL Registered in Supabase:**
   * In the Supabase console (both locally in `config.toml` and in production), add the native redirect URI to the allowed authentication URLs (Redirect URLs):
     ```text
     playfit://auth/callback
     ```
3. **SwiftUI Authentication Flow:**
   * When invoking OAuth authentication with the `"google"` provider, the Supabase Swift SDK client must send the redirect request to the native URL:
     ```swift
     let url = supabase.auth.getOAuthSignInUrl(
         provider: "google",
         redirectTo: URL(string: "playfit://auth/callback")
     )
     ```
   * Use `ASWebAuthenticationSession` to capture the redirect securely inside the native app and complete the user's session transparently.
