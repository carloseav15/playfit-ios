# Architecture

## Intent

Playfit for iOS should be a native product showcase, not a thin wrapper around the web app. It borrows the product contract and information architecture from the Playfit web product, but it should use iOS-native navigation, materials, gestures, persistence, and accessibility.

## Package Targets

`PlayfitModels`

Domain models shared by native features: games, recommendations, user game state, recommendation reasons, and taste profile.

`PlayfitMocks`

Stable mock data used to design UI before network and auth are introduced.

`PlayfitDesignSystem`

Reusable SwiftUI surfaces: spacing, glass-style cards, cover placeholders, score badges, and token rows. This is where future Liquid Glass wrappers should live.

`PlayfitLogic`

Domain rules shared by native features: recommendation and profile logic that mirrors the web product's `@playfit/core` package.

`PlayfitAPI`

Network client for the product backend: HTTP client, auth session handling (including Supabase auth), device identity, and typed API errors.

`PlayfitStorage`

Local persistence via SwiftData: cached recommendations, saved picks, per-game user state, and pending offline actions.

`PlayfitFeatures`

User-facing screens:

- `PlayfitRootView`
- `TodayView`
- `GameDetailView`
- `PicksView`
- `TasteView`
- `SettingsView`

## Data Direction

`PlayfitMocks` still backs early UI work, but `PlayfitAPI` and `PlayfitStorage` are implemented and wired into `PlayfitFeatures`:

- `PlayfitAPI` consumes the product backend (recommendations, profile, games, auth) over HTTP.
- `PlayfitStorage` persists cached recommendations, saved picks, user game states, and pending offline actions via SwiftData.

## Design Direction

Use Liquid Glass as an Apple-native material layer, not as decoration. Standard SwiftUI controls, toolbars, tab bars, sheets, and navigation should do most of the work. Custom glass surfaces should be reserved for high-value moments such as the featured recommendation card and bottom action bar.

## Repo Boundary

The source product remains:

```text
/Users/carancibia/Projects/playfit/product
```

The native iOS showcase lives here:

```text
/Users/carancibia/Projects/playfit/ios-swiftui
```
