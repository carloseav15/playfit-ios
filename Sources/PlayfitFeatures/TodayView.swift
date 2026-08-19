import PlayfitDesignSystem
import PlayfitLogic
import PlayfitModels
import SwiftUI

public struct TodayView: View {
    @Environment(\.playViewModel) private var viewModel
    @State private var selectedEntry: RankedRecommendation?
    @State private var showAlreadyPlayed = false
    @State private var slowLoading = false
    @State private var showPlatformsSheet = false

    public init() {}

    public var body: some View {
        ZStack {
            Color.playfitBackground.ignoresSafeArea()
            PlayfitGlowBackground()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: PlayfitSpacing.lg) {
                    if viewModel.isLoading {
                        TodayLoadingState(
                            slowLoading: slowLoading,
                            statusMessage: viewModel.canonicalStatusMessage
                        )
                            .task {
                                try? await Task.sleep(for: .seconds(3))
                                slowLoading = true
                            }
                    } else if let canonicalStatus = viewModel.canonicalStatusMessage {
                        canonicalStatusState(canonicalStatus)
                    } else if let error = viewModel.error {
                        errorState(error)
                    } else if let primary = viewModel.primary {
                        PrimaryRecommendationCard(
                            entry: primary,
                            selectedEntry: $selectedEntry,
                            showAlreadyPlayed: $showAlreadyPlayed
                        )
                        .id(primary.game.id)
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                        header

                        if !viewModel.alternatives.isEmpty {
                            alternativesSection
                        }
                    } else {
                        TodayEmptyState(showPlatformsSheet: $showPlatformsSheet)
                    }
                }
                .padding(PlayfitSpacing.md)
            }
            .refreshable {
                await viewModel.syncIfOnline()
            }
        }
        .navigationTitle("Play Next")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: PlayfitSpacing.sm) {
            Text(recommendationGroupTitle(for: viewModel.visiblePool))
                .font(.title2.bold())

            Text("Find what to play next, save promising picks, and keep the reasons visible. Only games available on your selected platforms are suggested.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            let profile = viewModel.profile
            if profile.ratedCount < 3 {
                Text("✨ Rate \(3 - profile.ratedCount) more game\(3 - profile.ratedCount == 1 ? "" : "s") to unlock detailed match reasons.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            SignalSummaryBar(
                preferencesCount: profile.ratedCount,
                likedCount: profile.likedGenres.count,
                avoidedCount: profile.avoidedGenres.count
            )

            if viewModel.pendingActionsCount > 0 {
                Label(
                    "\(viewModel.pendingActionsCount) change\(viewModel.pendingActionsCount == 1 ? "" : "s") waiting to sync",
                    systemImage: "icloud.and.arrow.up"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: PlayfitSpacing.sm) {
            Text("Play Next could not load")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Try Again") {
                slowLoading = false
                Task { await viewModel.syncIfOnline() }
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Try reloading recommendations")
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private func canonicalStatusState(_ message: String) -> some View {
        VStack(spacing: PlayfitSpacing.sm) {
            Image(systemName: "icloud.and.arrow.up")
                .font(.title2)
                .foregroundStyle(Color.playfitAccent)
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
            if viewModel.apiClient != nil {
                Button("Retry") { Task { await viewModel.syncIfOnline() } }
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private var alternativesSection: some View {
        VStack(alignment: .leading, spacing: PlayfitSpacing.sm) {
            Text("Also worth considering")
                .font(.title2.bold())

            Text("Other potential candidates matching your preferences.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(viewModel.alternatives) { entry in
                NavigationLink {
                    GameDetailView(entry: entry)
                } label: {
                    CompactRecommendationRow(entry: entry)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View details for \(entry.game.title)")
            }
        }
    }
}
