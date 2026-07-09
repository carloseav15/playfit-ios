import PlayfitDesignSystem
import PlayfitModels
import SwiftUI

enum OnboardingSearchTarget: Equatable {
    case liked(Int)
    case disliked
}

public struct OnboardingView: View {
    @Environment(\.playViewModel) private var viewModel
    @AppStorage(StorageKeys.appearanceMode) private var appearanceMode: AppearanceMode = .system
    @State private var step = 0
    @State private var selectedPlatformIds: Set<String> = []
    @State private var likedGames: [Game] = []
    @State private var dislikedGame: Game? = nil
    @State private var searchQuery = ""
    @State private var showSearch = false
    @State private var showPlatformDetails = false
    @State private var searchTarget: OnboardingSearchTarget = .liked(0)
    @State private var searchResults: [Game] = []
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var pendingSearchTask: Task<Void, Never>?

    private let suggestions = ["Elden Ring", "Hades", "Hollow Knight", "Portal 2", "The Witcher 3"]

    let onComplete: () -> Void
    let onCancel: (() -> Void)?

    public init(onComplete: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        self.onComplete = onComplete
        self.onCancel = onCancel
    }

    public var body: some View {
        ZStack {
            Color.playfitBackground.ignoresSafeArea()
            PlayfitGlowBackground()

            VStack(spacing: 0) {
                headerBar
                stepIndicator
                stepContent
            }
        }
        .foregroundStyle(Color.playfitForeground)
    }

    private var headerBar: some View {
        HStack {
            themePickerButton
            Spacer()
            if let onCancel {
                Button {
                    onCancel()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.bold))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancel setup")
            }
        }
        .padding(.horizontal, PlayfitSpacing.md)
        .padding(.top, PlayfitSpacing.sm)
    }

    private var themePickerButton: some View {
        Menu {
            Picker("Appearance", selection: $appearanceMode) {
                Label("Light", systemImage: "sun.max").tag(AppearanceMode.light)
                Label("Dark", systemImage: "moon").tag(AppearanceMode.dark)
                Label("System", systemImage: "gearshape").tag(AppearanceMode.system)
            }
        } label: {
            Image(systemName: appearanceModeIcon)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(8)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private var appearanceModeIcon: String {
        switch appearanceMode {
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        case .system: "circle.lefthalf.striped.horizontal"
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: PlayfitSpacing.sm) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(i <= step ? Color.playfitAccent : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, PlayfitSpacing.md)
    }

    @ViewBuilder
    private var stepContent: some View {
        ZStack {
            switch step {
            case 0:
                OnboardingPlatformsStep(
                    selectedPlatformIds: $selectedPlatformIds,
                    showPlatformDetails: $showPlatformDetails,
                    onContinue: { withAnimation { step = 1 } }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 1:
                OnboardingLikedGamesStep(
                    likedGames: $likedGames,
                    searchTarget: $searchTarget,
                    showSearch: $showSearch,
                    onBack: { withAnimation { step = 0 } },
                    onContinue: { withAnimation { step = 2 } }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 2:
                OnboardingDislikedGameStep(
                    dislikedGame: $dislikedGame,
                    searchTarget: $searchTarget,
                    showSearch: $showSearch,
                    onBack: { withAnimation { step = 1 } },
                    onComplete: completeOnboarding
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            default:
                EmptyView()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
        .sheet(isPresented: $showSearch) {
            OnboardingGameSearchSheet(
                suggestions: suggestions,
                searchQuery: $searchQuery,
                searchResults: $searchResults,
                isSearching: $isSearching,
                searchError: $searchError,
                onCancel: resetSearch,
                onQueryChange: searchTask,
                onSelect: selectGame
            )
        }
        .sheet(isPresented: $showPlatformDetails) {
            CustomizePlatformsView(selectedPlatformIds: $selectedPlatformIds)
                .environment(\.playViewModel, viewModel)
        }
    }

    private func searchTask(_ query: String) {
        pendingSearchTask?.cancel()
        searchError = nil
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        pendingSearchTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            do {
                let results = try await viewModel.searchGames(query: query)
                guard !Task.isCancelled, query == searchQuery else { return }
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                guard !Task.isCancelled, query == searchQuery else { return }
                await MainActor.run {
                    searchError = "Something went wrong. Please try again."
                    isSearching = false
                }
            }
        }
    }

    private func selectGame(_ game: Game) {
        switch searchTarget {
        case .liked(let index):
            if dislikedGame?.id == game.id {
                dislikedGame = nil
            }
            if index < likedGames.count {
                likedGames[index] = game
            } else {
                likedGames.append(game)
            }
        case .disliked:
            likedGames.removeAll { $0.id == game.id }
            dislikedGame = game
        }
        resetSearch()
    }

    private func resetSearch() {
        showSearch = false
        searchQuery = ""
        searchResults = []
        searchError = nil
    }

    private func completeOnboarding() {
        Task {
            await viewModel.completeOnboarding(
                selectedPlatformIds: selectedPlatformIds,
                likedGames: likedGames,
                dislikedGame: dislikedGame
            )
            onComplete()
        }
    }
}
