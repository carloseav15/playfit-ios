import PlayfitDesignSystem
import PlayfitLogic
import PlayfitModels
import SwiftUI

struct OnboardingDislikedGameStep: View {
    @Binding var dislikedGame: Game?
    @Binding var searchTarget: OnboardingSearchTarget
    @Binding var showSearch: Bool
    let onBack: () -> Void
    let onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PlayfitSpacing.lg) {
                Text("Pick one game that wasn't for you")
                    .font(.largeTitle.weight(.black))

                Text("Tell us a popular game you didn't enjoy so we know what to avoid.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let game = dislikedGame {
                    PlayfitGlassCard {
                        HStack(spacing: PlayfitSpacing.md) {
                            PlayfitGameCover(game: game)
                                .frame(width: 64)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(game.title)
                                    .font(.headline)
                                    .lineLimit(1)
                                Text(game.genres.map(formatDisplayGenre).joined(separator: " / "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                dislikedGame = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Remove \(game.title)")
                        }
                    }
                } else {
                    Button {
                        searchTarget = .disliked
                        showSearch = true
                    } label: {
                        Label("Add a game", systemImage: "plus.circle")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(PlayfitSpacing.lg)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add a game that was not for you")
                }

                Spacer(minLength: 24)

                HStack(spacing: PlayfitSpacing.md) {
                    Button {
                        onBack()
                    } label: {
                        Text("Back")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)

                    Button(action: onComplete) {
                        Text("Find Play Next")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(dislikedGame == nil)
                }
            }
            .padding(PlayfitSpacing.md)
        }
    }
}
