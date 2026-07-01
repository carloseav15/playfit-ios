# Architecture

## Intent

Playfit for iOS should be a native product showcase, not a thin wrapper around the web app. It borrows the product contract and information architecture from `/play`, but it should use iOS-native navigation, materials, gestures, persistence, and accessibility.

## Package Targets

`PlayfitModels`

Domain models shared by native features: games, recommendations, user game state, recommendation reasons, and taste profile.

`PlayfitMocks`

Stable mock data used to design UI before network and auth are introduced.

`PlayfitDesignSystem`

Reusable SwiftUI surfaces: spacing, glass-style cards, cover placeholders, score badges, and token rows. This is where future Liquid Glass wrappers should live.

`PlayfitFeatures`

User-facing screens:

- `PlayfitRootView`
- `TodayView`
- `GameDetailView`
- `PicksView`
- `TasteView`
- `SettingsView`

## Data Direction

Phase 1 uses mock data only.

Phase 2 should introduce API clients that consume the product backend:

- `GET /api/recommendations/today`
- `GET /api/profile`
- `PATCH /api/profile/games/:gameId`
- `GET /api/recommendations/picks`
- `GET /api/games`
- `POST /api/games/batch`

Phase 3 should add SwiftData:

- cached recommendations
- saved picks
- user game states
- pending offline actions
- last successful sync timestamp

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
