# playfit-ios

**Public portfolio project.** Native iOS showcase for the [Playfit](https://github.com/carloseav15/playfit) product experience.

Playfit recommends games based on what you actually like, not what's popular. This repo is the
native iOS showcase of that product; full product context lives at
[github.com/carloseav15/playfit](https://github.com/carloseav15/playfit).

This repo is a subordinate/portfolio implementation of the Playfit mobile product vision.

The code is organized as a Swift Package consumed by the `PlayfitIOS` Xcode app target. This keeps domain, API, storage, design-system, and feature code reviewable from the terminal while preserving a native iOS app entry point.

## Scope

The iOS app should reinterpret the mobile Playfit product flow from the web app:

- `Today / Play Next`: one strong recommendation plus a short queue.
- `Game Detail`: cover, metadata, recommendation reasons, and action buttons.
- `Picks`: saved recommendations.
- `Taste`: taste profile and platform/genre/tag signals.
- `Settings`: auth, sync, and preference controls.

This is not a full web port. The target is a native iOS showcase that feels current on Apple platforms.

## Current Stack

- Swift 6 package layout.
- SwiftUI views.
- Typed API clients for Playfit and Supabase authentication.
- SwiftData-backed local cache and pending offline actions.
- Modular targets for models, mocks, design system, logic, API, storage, and features.
- CLI smoke check executable plus package and Xcode UI tests.

## Platform and Validation

- SwiftUI for UI on iOS 18 and newer.
- Observation-compatible state flow through the main-actor `PlayViewModel`.
- SwiftData for offline cache and sync queue.
- Typed URLSession clients for Playfit and Supabase auth endpoints.
- Standard Apple materials and controls, with selective custom glass surfaces.
- XCTest package tests and deterministic Xcode UI tests.

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

The app target, bundle identifier, app icon catalog, and simulator validation are present. Review signing, release configuration, and final icon artwork before App Store/TestFlight work.

## Next Milestones

1. Split the largest synchronization, authentication, and visualization files by responsibility.
2. Expand error-path, sync-queue, and accessibility coverage.
3. Validate the final Liquid Glass treatment on the current iOS simulator and a physical device.
4. Complete signing and release configuration for TestFlight.
