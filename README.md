# playfit-ios

**Public portfolio project.** Native iOS showcase for the [Playfit](https://github.com/carloseav15/playfit) `/play` experience.

This repo is a subordinate/portfolio implementation of the Playfit mobile product vision. The main project ecosystem lives at [github.com/carloseav15/playfit](https://github.com/carloseav15/playfit).

This folder intentionally starts as a Swift Package, not an Xcode project. The goal is to keep the first pass reviewable from the terminal, then create the Xcode app target once signing, bundle id, app icons, and simulator validation are ready.

## Scope

The iOS app should reinterpret the mobile `/play` product flow from the web app:

- `Today / Play Next`: one strong recommendation plus a short queue.
- `Game Detail`: cover, metadata, recommendation reasons, and action buttons.
- `Picks`: saved recommendations.
- `Taste`: taste profile and platform/genre/tag signals.
- `Settings`: auth, sync, and preference controls.

This is not a full web port. The target is a native iOS showcase that feels current on Apple platforms.

## Current Stack

- Swift 6 package layout.
- SwiftUI views.
- Mock data while the native UI is shaped.
- Modular targets for models, mocks, design system, and features.
- CLI smoke check executable for environments without full Xcode test support.

## Intended 2026 Stack

- SwiftUI for UI.
- Observation for app state.
- SwiftData for offline cache and sync queue.
- Supabase Swift SDK for auth and API access.
- Liquid Glass through standard Apple components first, then selective custom glass surfaces.
- Swift Testing or XCTest once the full Xcode app target exists.

## Folder Layout

```text
ios-swiftui/
  PlayfitIOS.xcodeproj
  PlayfitIOS/
    PlayfitIOSApp.swift
    Assets.xcassets/
  Package.swift
  Sources/
    PlayfitModels/
    PlayfitMocks/
    PlayfitDesignSystem/
    PlayfitFeatures/
  docs/
```

## Terminal Validation

```sh
swift build
swift run PlayfitSmokeCheck
```

## Xcode Validation

The app target is `PlayfitIOS` and uses the local Swift package products.

```sh
xcodebuild \
  -project PlayfitIOS.xcodeproj \
  -scheme PlayfitIOS \
  -configuration Debug \
  -destination 'id=A91125EB-0BF3-4F0B-BDA7-67AA304CD27E' \
  build
```

The current app icon is intentionally unset. Add a real Playfit app icon before App Store/TestFlight work.

## Next Milestones

1. Open this package in Xcode and create a real iOS app target.
2. Add app icons, bundle id, signing, and launch screen.
3. Replace mock data with API clients for Playfit product endpoints.
4. Add SwiftData persistence for recommendations, picks, and pending actions.
5. Validate Liquid Glass treatment on iOS 26 simulator/device.
