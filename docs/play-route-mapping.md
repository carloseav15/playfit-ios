# `/play` to iOS Mapping

The native iOS app should start from the web `/play` mobile flow, but it should not copy React components directly.

## Source Web Routes

```text
/play
/play/game/[gameId]
/play/picks
/play/taste
/play/settings
```

Source files:

```text
/Users/carancibia/Projects/playfit/product/apps/web/src/app/play
/Users/carancibia/Projects/playfit/product/apps/web/src/components/playfit-mvp
```

## Native iOS Destinations

| Web route | iOS screen | SwiftUI file |
| --- | --- | --- |
| `/play` | Today / Play Next | `TodayView.swift` |
| `/play/game/[gameId]` | Game Detail | `GameDetailView.swift` |
| `/play/picks` | Picks | `PicksView.swift` |
| `/play/taste` | Taste | `TasteView.swift` |
| `/play/settings` | Settings | `SettingsView.swift` |

## Product Contract

The first iOS version should prove:

- A user can see one primary recommendation.
- A user can inspect why the recommendation fits.
- A user can save, skip, or mark a game as played.
- A user can open saved picks.
- A user can understand their taste profile.
- The app still feels useful with cached data.

## Non-goals

- Do not port the full web app.
- Do not use a web view.
- Do not start with auth complexity before the native interaction model is solid.
- Do not overuse Liquid Glass where it harms readability.
