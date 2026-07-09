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
            .searchable(text: $searchQuery, prompt: "Search games...")
            .searchSuggestions {
                if searchQuery.isEmpty {
                    ForEach(suggestions, id: \.self) { title in
                        Button(title) {
                            searchQuery = title
                        }
                    }
                }
            }
            .onChange(of: searchQuery) { _, newValue in
                onQueryChange(newValue)
            }
        }
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
                    .padding(14)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title)
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

                                if !formatDisplayGenre(game.primaryGenre).isEmpty || isValidReleaseYear(game.releaseYear) || !game.availablePlatformNames.isEmpty {
                                    let metadataParts: [String] = {
                                        var parts: [String] = []
                                        let genre = formatDisplayGenre(game.primaryGenre)
                                        if !genre.isEmpty { parts.append(genre) }
                                        if isValidReleaseYear(game.releaseYear) {
                                            parts.append(game.releaseYear ?? "")
                                        }
                                        if !game.availablePlatformNames.isEmpty {
                                            let names = game.availablePlatformNames.prefix(3).joined(separator: ", ")
                                            let suffix = game.availablePlatformNames.count > 3 ? "..." : ""
                                            parts.append(names + suffix)
                                        }
                                        return parts
                                    }()

                                    Text(metadataParts.joined(separator: " • "))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "plus.circle")
                                .foregroundColor(.playfitAccent)
                        }
                        .frame(minHeight: 44)
                        .padding(PlayfitSpacing.sm)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(game.title)
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
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
