import PlayfitDesignSystem
import PlayfitLogic
import PlayfitModels
import SwiftUI

struct OnboardingLikedGamesStep: View {
    @Binding var likedGames: [Game]
    @Binding var searchTarget: OnboardingSearchTarget
    @Binding var showSearch: Bool
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PlayfitSpacing.lg) {
                Text("Pick three games you loved")
                    .font(.largeTitle.weight(.black))

                Text("Start with games that clicked. We will look for similar games.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(0..<3, id: \.self) { index in
                    likedGameSlot(index: index)
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

                    Button {
                        onContinue()
                    } label: {
                        Text("Continue")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(likedGames.count < 3)
                }
            }
            .padding(PlayfitSpacing.md)
        }
    }

    private func likedGameSlot(index: Int) -> some View {
        HStack {
            if index < likedGames.count {
                let game = likedGames[index]
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
                            likedGames.remove(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.title3)
                        }
                        .accessibilityLabel("Remove \(game.title)")
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Button {
                    searchTarget = .liked(index)
                    showSearch = true
                } label: {
                    Label("Add a loved game", systemImage: "plus.circle")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(PlayfitSpacing.md)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add a loved game")
            }
        }
    }
}
