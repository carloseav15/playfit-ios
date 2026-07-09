import PlayfitDesignSystem
import PlayfitLogic
import PlayfitModels
import SwiftUI

struct CompactRecommendationRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let entry: RankedRecommendation

    var body: some View {
        PlayfitGlassCard {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: PlayfitSpacing.sm))
                : AnyLayout(HStackLayout(spacing: PlayfitSpacing.md))
            layout {
                PlayfitGameCover(game: entry.game)
                    .frame(width: dynamicTypeSize.isAccessibilitySize ? 120 : 76)

                VStack(alignment: .leading, spacing: PlayfitSpacing.xs) {
                    Text("Worth checking")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(entry.game.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(entry.game.genres.map(formatDisplayGenre).joined(separator: " / "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("\(entry.affinityScore)% Match")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.playfitAccent)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .accessibilityLabel("\(entry.game.title), \(entry.affinityScore) percent match")
    }
}
