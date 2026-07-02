import PlayfitAPI
import PlayfitDesignSystem
import PlayfitLogic
import PlayfitModels
import SwiftUI

public struct GameDetailView: View {
    @Environment(\.playViewModel) private var viewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let gameId: String
    private let hasRecommendationContext: Bool
    @State private var entry: RankedRecommendation?
    @State private var isLoading: Bool
    @State private var isNotFound = false
    @State private var loadError: String?
    @State private var showAlreadyPlayed = false

    public init(entry: RankedRecommendation) {
        self.gameId = entry.game.id
        self.hasRecommendationContext = true
        self._entry = State(initialValue: entry)
        self._isLoading = State(initialValue: false)
    }

    public init(gameId: String) {
        self.gameId = gameId
        self.hasRecommendationContext = false
        self._entry = State(initialValue: nil)
        self._isLoading = State(initialValue: true)
    }

    public var body: some View {
        ZStack {
            Color.playfitBackground.ignoresSafeArea()
            glowBackground

            if isLoading && entry == nil {
                ProgressView("Loading game details…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isNotFound {
                ContentUnavailableView(
                    "Game not found",
                    systemImage: "questionmark.folder",
                    description: Text("This game may have been removed or redirected.")
                )
            } else if let loadError, entry == nil {
                ContentUnavailableView {
                    Label("Could not load game", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(loadError)
                } actions: {
                    Button("Try Again") { Task { await loadGame() } }
                        .buttonStyle(.borderedProminent)
                }
            } else if let entry {
                detailContent(entry)
            }
        }
        .navigationTitle(entry?.game.title ?? "Game Details")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .safeAreaInset(edge: .bottom) {
            if let entry { dossierActions(entry) }
        }
        .overlay(alignment: .top) {
            if isLoading && entry != nil {
                ProgressView()
                    .padding(10)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.top, 8)
            }
        }
        .sheet(isPresented: $showAlreadyPlayed) {
            if let entry {
                AlreadyPlayedSheet { feedback in
                    viewModel.alreadyPlayed(entry, feedback: feedback)
                    showAlreadyPlayed = false
                }
            }
        }
        .task(id: gameId) { await loadGame() }
    }

    private func detailContent(_ entry: RankedRecommendation) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PlayfitSpacing.lg) {
                PlayfitGameCover(game: entry.game)
                    .frame(maxWidth: 260)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: PlayfitSpacing.sm) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: PlayfitSpacing.xs) {
                            Text(entry.game.title).font(.largeTitle.bold())
                            if let year = entry.game.releaseYear {
                                Text(year).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if hasRecommendationContext {
                            ScoreBadge(score: Double(entry.affinityScore) / 100.0)
                        }
                    }

                    if hasRecommendationContext {
                        HStack(spacing: PlayfitSpacing.sm) {
                            Text("Recommended")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.playfitAccent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.playfitAccent.opacity(0.12), in: Capsule())
                            DecisionLabelBadge(label: decisionLabel(for: entry), tone: decisionTone(for: entry))
                        }
                    }

                    if !entry.game.primaryGenre.isEmpty {
                        Text(entry.game.primaryGenre).font(.subheadline).foregroundStyle(.secondary)
                    }

                    if !entry.game.availablePlatformNames.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(entry.game.availablePlatformNames, id: \.self) { platform in
                                    Text(platform)
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.thinMaterial, in: Capsule())
                                }
                            }
                        }
                    }
                }

                if hasRecommendationContext {
                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.flexible()),
                            count: dynamicTypeSize.isAccessibilitySize ? 1 : 3
                        ),
                        spacing: PlayfitSpacing.sm
                    ) {
                        RecommendationMetric(label: "Match Affinity", value: "\(entry.affinityScore)%", numericValue: entry.affinityScore, color: .playfitAccent)
                        RecommendationMetric(label: "Watch-out Score", value: "\(entry.riskScore)%", numericValue: entry.riskScore, color: entry.riskScore > 45 ? .red : .orange)
                        RecommendationMetric(label: "Confidence Read", value: confidenceLabel(entry.confidence), color: .playfitAccent)
                    }

                    if !entry.fitReasons.isEmpty {
                        FitReasonsCard(title: "Why it fits", reasons: entry.fitReasons, tone: .positive)
                    } else {
                        Text("Playfit needs more feedback before making a strong claim.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }

                    let cautions = filterUsefulCautions(entry.cautionReasons)
                    if !cautions.isEmpty {
                        FitReasonsCard(title: "Watch-outs", reasons: cautions, tone: .warning)
                    }
                } else {
                    PlayfitGlassCard {
                        VStack(alignment: .leading, spacing: PlayfitSpacing.sm) {
                            Text("Catalog Details").font(.headline)
                            if !entry.game.series.isEmpty { LabeledContent("Series", value: entry.game.series) }
                            if !entry.game.tags.isEmpty {
                                LabeledContent("Traits", value: entry.game.tags.prefix(5).map(formatTagLabel).joined(separator: ", "))
                            }
                            if !entry.game.aliases.isEmpty {
                                LabeledContent("Also known as", value: entry.game.aliases.prefix(3).joined(separator: ", "))
                            }
                        }
                        .padding(PlayfitSpacing.md)
                    }
                }
            }
            .padding(PlayfitSpacing.md)
        }
    }

    private func dossierActions(_ entry: RankedRecommendation) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: PlayfitSpacing.sm))
            : AnyLayout(HStackLayout(spacing: PlayfitSpacing.md))

        return layout {
            Button {
                if viewModel.isPicked(entry.game.id) {
                    viewModel.removePick(entry.game.id)
                } else {
                    viewModel.addPick(entry)
                }
            } label: {
                Label(
                    viewModel.isPicked(entry.game.id) ? "Remove from Picks" : "Save to Picks",
                    systemImage: viewModel.isPicked(entry.game.id) ? "bookmark.fill" : "bookmark"
                )
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button { showAlreadyPlayed = true } label: {
                Label("Already played", systemImage: "checkmark.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button { viewModel.notForMe(entry) } label: {
                Label("Not for me", systemImage: "xmark.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.playfitNegative)
        }
        .padding(PlayfitSpacing.md)
        .background(.regularMaterial)
    }

    @MainActor
    private func loadGame() async {
        guard let apiClient = viewModel.apiClient else {
            if entry == nil { loadError = "No backend connection is configured." }
            isLoading = false
            return
        }
        isLoading = true
        isNotFound = false
        loadError = nil
        do {
            guard let game = try await apiClient.fetchGame(gameId: gameId) else {
                entry = nil
                isNotFound = true
                isLoading = false
                return
            }
            viewModel.gamesCache[game.id] = game
            if var current = entry {
                current.game = game
                entry = current
            } else {
                entry = RankedRecommendation(
                    game: game,
                    affinityScore: 0,
                    riskScore: 0,
                    confidence: .low,
                    fitReasons: [],
                    cautionReasons: [],
                    inPlayfitPicks: viewModel.isPicked(game.id)
                )
            }
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    private var glowBackground: some View {
        GeometryReader { geometry in
            ZStack {
                Circle().fill(Color.playfitAccent.opacity(0.12)).frame(width: 320, height: 320).blur(radius: 80)
                    .position(x: geometry.size.width - 50, y: 100)
                Circle().fill(Color.playfitToneAccent.opacity(0.08)).frame(width: 280, height: 280).blur(radius: 70)
                    .position(x: 50, y: geometry.size.height - 150)
            }
            .ignoresSafeArea()
        }
    }
}
