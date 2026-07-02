import PlayfitAPI
import PlayfitDesignSystem
import PlayfitLogic
import PlayfitModels
import PlayfitStorage
import SwiftUI

struct PlatformPreset: Identifiable {
    let id: String
    let label: String
    let description: String
    let icon: String
    let match: (Platform) -> Bool
}

public struct OnboardingView: View {
    @Environment(\.playViewModel) private var viewModel
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @State private var step = 0
    @State private var selectedPlatformIds: Set<String> = []
    @State private var likedGames: [Game] = []
    @State private var dislikedGame: Game? = nil
    @State private var searchQuery = ""
    @State private var showSearch = false
    @State private var showPlatformDetails = false
    @State private var searchTarget: SearchTarget = .liked(0)
    @State private var searchResults: [Game] = []
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var pendingSearchTask: Task<Void, Never>?

    enum SearchTarget: Equatable {
        case liked(Int)
        case disliked
    }

    private let platformPresets: [PlatformPreset] = [
        PlatformPreset(id: "current", label: "Current systems", description: "Modern consoles and computers.", icon: "gamecontroller.fill", match: { ["switch_1", "ps5", "xbox_series_xs", "pc", "macos"].contains($0.platformId) }),
        PlatformPreset(id: "nintendo", label: "Nintendo", description: "Switch, handhelds, and classic Nintendo.", icon: "gamecontroller.fill", match: { $0.family == "nintendo" }),
        PlatformPreset(id: "playstation", label: "PlayStation", description: "Sony home and handheld systems.", icon: "gamecontroller.fill", match: { $0.family == "playstation" }),
        PlatformPreset(id: "xbox", label: "Xbox", description: "Xbox generations and current consoles.", icon: "gamecontroller.fill", match: { $0.family == "xbox" }),
        PlatformPreset(id: "pc", label: "PC", description: "Desktop and computer platforms.", icon: "laptopcomputer", match: { $0.family == "pc" || $0.kind == "computer" }),
        PlatformPreset(id: "retro", label: "Retro", description: "Older consoles and handhelds.", icon: "tv", match: { 
            ["snes", "n64", "wii", "ps2", "ps3", "xbox_360"].contains($0.platformId) ||
            ["sega", "atari", "snk", "neogeo"].contains($0.family)
        })
    ]

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
            
            glowBackground
            
            VStack(spacing: 0) {
                headerBar
                stepIndicator
                stepContent
            }
        }
        .foregroundStyle(Color.playfitForeground)
    }

    private var glowBackground: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(Color.playfitAccent.opacity(0.12))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .position(x: geometry.size.width - 50, y: 100)
                
                Circle()
                    .fill(Color.playfitToneAccent.opacity(0.08))
                    .frame(width: 280, height: 280)
                    .blur(radius: 70)
                    .position(x: 50, y: geometry.size.height - 150)
            }
            .ignoresSafeArea()
        }
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

    // MARK: - Step Indicator

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

    // MARK: - Step Content (No Swipe)

    @ViewBuilder
    private var stepContent: some View {
        ZStack {
            switch step {
            case 0:
                platformsStep
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 1:
                likedGamesStep
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 2:
                dislikedGameStep
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            default:
                EmptyView()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
    }

    // MARK: - Step 1: Platforms

    private var platformsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PlayfitSpacing.lg) {
                Text("Where do you play?")
                    .font(.largeTitle.weight(.black))

                Text("We will only recommend games available on your active platforms.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Quick Groups")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(platformPresets, id: \.id) { preset in
                        let selectedCount = presetSelectedCount(preset)
                        let fullySelected = isPresetFullySelected(preset)
                        let partiallySelected = selectedCount > 0 && !fullySelected

                        Button {
                            withAnimation {
                                togglePreset(preset)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                Color.clear.frame(height: 0) // Anchor structure
                                HStack {
                                    Image(systemName: preset.icon)
                                        .font(.title3)
                                        .foregroundStyle(fullySelected ? Color.playfitAccent : Color.secondary)
                                    Spacer()
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.label)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.primary)
                                    Text(preset.description)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                
                                if fullySelected {
                                    Text("Selected")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(Color.playfitAccent)
                                } else if partiallySelected {
                                    Text("\(selectedCount) Selected")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(Color.secondary)
                                } else {
                                    Text("Tap to Select")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                fullySelected ? Color.playfitAccent.opacity(0.12) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        fullySelected ? Color.playfitAccent.opacity(0.4) : Color.primary.opacity(0.06),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer(minLength: 24)

                VStack(spacing: 12) {
                    Button {
                        showPlatformDetails = true
                    } label: {
                        Text("Customize Platforms...")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.playfitAccent)
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation { step = 1 }
                    } label: {
                        Text(selectedPlatformIds.isEmpty ? "Select at least one system" : "Continue")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedPlatformIds.isEmpty)
                }
            }
            .padding(PlayfitSpacing.md)
        }
        .sheet(isPresented: $showPlatformDetails) {
            CustomizePlatformsView(selectedPlatformIds: $selectedPlatformIds)
                .environment(\.playViewModel, viewModel)
        }
    }

    // MARK: - Step 2: Liked Games

    private var likedGamesStep: some View {
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
                        withAnimation { step = 0 }
                    } label: {
                        Text("Back")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        withAnimation { step = 2 }
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
        .sheet(isPresented: $showSearch) {
            gameSearchSheet
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
            }
        }
    }

    // MARK: - Step 3: Disliked Game

    private var dislikedGameStep: some View {
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
                }

                Spacer(minLength: 24)

                HStack(spacing: PlayfitSpacing.md) {
                    Button {
                        withAnimation { step = 1 }
                    } label: {
                        Text("Back")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)

                    Button(action: completeOnboarding) {
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
        .sheet(isPresented: $showSearch) {
            gameSearchSheet
        }
    }

    // MARK: - Search Sheet

    private var gameSearchSheet: some View {
        NavigationStack {
            VStack(spacing: PlayfitSpacing.md) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search games...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                }
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))

                if searchQuery.isEmpty {
                    quickSuggestions
                } else if isSearching {
                    VStack(spacing: PlayfitSpacing.sm) {
                        ProgressView()
                        Text("Searching...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else if let error = searchError {
                    VStack(spacing: PlayfitSpacing.sm) {
                        Image(systemName: "exclamationmark.magnifyingglass")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else if searchResults.isEmpty {
                    VStack(spacing: PlayfitSpacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No games found for \"\(searchQuery)\"")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    searchResultsList
                }

                Spacer()
            }
            .padding(PlayfitSpacing.md)
            .navigationTitle("Search Games")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showSearch = false
                        searchQuery = ""
                        searchResults = []
                        searchError = nil
                    }
                }
            }
            .onChange(of: searchQuery) { _, newValue in
                searchTask(newValue)
            }
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
                        selectGame(game)
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

    // MARK: - Actions

    private func togglePreset(_ preset: PlatformPreset) {
        let presetPlatforms = viewModel.platforms.filter(preset.match)
        let presetIds = Set(presetPlatforms.map(\.platformId))
        let allSelected = presetIds.allSatisfy { selectedPlatformIds.contains($0) }
        
        if allSelected {
            selectedPlatformIds.subtract(presetIds)
        } else {
            selectedPlatformIds.formUnion(presetIds)
        }
    }

    private func presetSelectedCount(_ preset: PlatformPreset) -> Int {
        let presetPlatforms = viewModel.platforms.filter(preset.match)
        let presetIds = Set(presetPlatforms.map(\.platformId))
        return presetIds.filter { selectedPlatformIds.contains($0) }.count
    }

    private func isPresetFullySelected(_ preset: PlatformPreset) -> Bool {
        let presetPlatforms = viewModel.platforms.filter(preset.match)
        let presetIds = Set(presetPlatforms.map(\.platformId))
        return !presetIds.isEmpty && presetIds.allSatisfy { selectedPlatformIds.contains($0) }
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
                let api = HTTPPlayfitClient(baseURL: PlayfitAPI.default)
                let results = try await api.searchGames(query: query)
                guard !Task.isCancelled, query == searchQuery else { return }
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                guard !Task.isCancelled, query == searchQuery else { return }
                await MainActor.run {
                    searchError = error.localizedDescription
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
        showSearch = false
        searchQuery = ""
    }

    private func completeOnboarding() {
        let completedAt = ISO8601DateFormatter().string(from: Date())
        viewModel.onboardingLikedGameIds = likedGames.map(\.id)
        viewModel.onboardingDislikedGameIds = dislikedGame.map { [$0.id] } ?? []
        viewModel.onboardingCompletedAt = completedAt

        for game in likedGames {
            viewModel.gamesCache[game.id] = game
            viewModel.gameStates[game.id] = UserGameState(
                source: "onboarding",
                createdAt: completedAt,
                updatedAt: completedAt
            )
        }
        if let miss = dislikedGame {
            viewModel.gamesCache[miss.id] = miss
            viewModel.gameStates[miss.id] = UserGameState(
                source: "onboarding",
                createdAt: completedAt,
                updatedAt: completedAt
            )
        }

        let profile = rebuildUserProfile(
            onboardingLikedIds: viewModel.onboardingLikedGameIds,
            onboardingDislikedIds: viewModel.onboardingDislikedGameIds,
            gameStates: viewModel.gameStates,
            gamesCache: viewModel.gamesCache
        )
        viewModel.profile = profile
        viewModel.selectedPlatformIds = selectedPlatformIds
        viewModel.onboardingCompleted = true

        let storage = LocalStorageService.shared
        storage.saveProfile(profile, platformIds: selectedPlatformIds, onboardingCompleted: true)
        storage.saveOnboardingMetadata(
            likedIds: viewModel.onboardingLikedGameIds,
            dislikedIds: viewModel.onboardingDislikedGameIds,
            completedAt: completedAt
        )

        // Upload the profile before handing off: `onComplete` triggers
        // `syncIfOnline()`, which asks the server for today's recommendations.
        // If that request lands before this upload does, the server has no
        // platforms/favorites on record yet and returns an empty (not
        // erroring) result — so the built-in needsResync retry never fires.
        Task {
            try? await viewModel.syncProfileToServer()
            onComplete()
        }
    }
}

// MARK: - Customize Platforms View

private struct CustomizePlatformsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.playViewModel) private var viewModel
    @Binding var selectedPlatformIds: Set<String>

    var body: some View {
        NavigationStack {
            List {
                let families = Dictionary(grouping: viewModel.platforms, by: { $0.family })
                ForEach(Array(families.keys).sorted(), id: \.self) { family in
                    Section(familyDisplayName(family)) {
                        ForEach(families[family]!, id: \.platformId) { platform in
                            Button {
                                if selectedPlatformIds.contains(platform.platformId) {
                                    selectedPlatformIds.remove(platform.platformId)
                                } else {
                                    selectedPlatformIds.insert(platform.platformId)
                                }
                            } label: {
                                HStack {
                                    Text(platform.displayName)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedPlatformIds.contains(platform.platformId) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.title3)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.tertiary)
                                            .font(.title3)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Customize Platforms")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func familyDisplayName(_ family: String) -> String {
        switch family {
        case "nintendo": "Nintendo"
        case "playstation": "PlayStation"
        case "xbox": "Xbox"
        case "pc": "PC"
        default: family.capitalized
        }
    }
}
