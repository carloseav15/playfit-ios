import PlayfitDesignSystem
import PlayfitLogic
import PlayfitModels
import SwiftUI

struct OnboardingGameSearchSheet: View {
    let suggestions: [String]
    @Binding var searchQuery: String
    @Binding var searchResults: [Game]
    @Binding var isSearching: Bool
    @Binding var searchError: String?
    let onCancel: () -> Void
    let onQueryChange: (String) -> Void
    let onSelect: (Game) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: PlayfitSpacing.md) {
                searchField
                searchContent
                Spacer()
            }
            .padding(PlayfitSpacing.md)
            .navigationTitle("Search Games")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
            .onChange(of: searchQuery) { _, newValue in
                onQueryChange(newValue)
            }
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search games...", text: $searchQuery)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var searchContent: some View {
        if searchQuery.isEmpty {
            quickSuggestions
        } else if isSearching {
            searchStatus(icon: nil, text: "Searching...")
        } else if let error = searchError {
            searchStatus(icon: "exclamationmark.magnifyingglass", text: error)
        } else if searchResults.isEmpty {
            searchStatus(icon: "magnifyingglass", text: "No games found for \"\(searchQuery)\"")
        } else {
            searchResultsList
        }
    }

    private var quickSuggestions: some View {
        VStack(alignment: .leading, spacing: PlayfitSpacing.sm) {
            Text("Quick Suggestions")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(suggestions, id: \.self) { title in
                Button {
                    searchQuery = title
                } label: {
                    HStack {
                        Text(title)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "plus.circle")
                            .foregroundColor(.playfitAccent)
                    }
                    .padding(PlayfitSpacing.sm)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: PlayfitSpacing.sm) {
                ForEach(searchResults, id: \.id) { game in
                    Button {
                        onSelect(game)
                    } label: {
                        HStack(spacing: PlayfitSpacing.sm) {
                            PlayfitGameCover(game: game)
                                .frame(width: 44)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(game.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                HStack(spacing: 4) {
                                    if !formatDisplayGenre(game.primaryGenre).isEmpty {
                                        Text(formatDisplayGenre(game.primaryGenre))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if isValidReleaseYear(game.releaseYear) {
                                        Text("• \(game.releaseYear ?? "")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }

                            Spacer()

                            Image(systemName: "plus.circle")
                                .foregroundColor(.playfitAccent)
                        }
                        .padding(PlayfitSpacing.sm)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func searchStatus(icon: String?, text: String) -> some View {
        VStack(spacing: PlayfitSpacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}
