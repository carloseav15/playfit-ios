import PlayfitDesignSystem
import PlayfitLogic
import PlayfitModels
import SwiftUI

public struct TodayView: View {
    @Environment(\.playViewModel) private var viewModel
    @State private var selectedEntry: RankedRecommendation?
    @State private var showReasonPicker = false
    @State private var showAlreadyPlayed = false
    @State private var slowLoading = false

    public init() {}

    public var body: some View {
        ZStack {
            Color.playfitBackground.ignoresSafeArea()
            
            glowBackground
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: PlayfitSpacing.lg) {
                    if viewModel.isLoading {
                        loadingState
                            .task {
                                try? await Task.sleep(for: .seconds(3))
                                slowLoading = true
                            }
                    } else if let error = viewModel.error {
                        errorState(error)
                    } else if let primary = viewModel.primary {
                        primarySection(primary)

                        if !viewModel.alternatives.isEmpty {
                            alternativesSection
                        }
                    } else {
                        emptyState
                    }
                }
                .padding(PlayfitSpacing.md)
            }
        }
        .navigationTitle("Play Next")
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: PlayfitSpacing.sm) {
            Text(recommendationGroupTitle(for: viewModel.visiblePool))
                .font(.largeTitle.bold())

            Text("Find what to play next, save promising picks, and keep the reasons visible. Only games available on your selected platforms are suggested.")
                .font(.body)
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

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: PlayfitSpacing.lg) {
            VStack(spacing: PlayfitSpacing.sm) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.playfitAccent)
                        .frame(width: 8, height: 8)
                    Text("Finding recommendations...")
                        .font(.headline)
                }

                Text("Checking your platforms, liked games, and preferences.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if slowLoading {
                Text("Analyzing the catalog. Your preferences are saved.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .background(.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: PlayfitSpacing.md) {
                ForEach(0..<3) { _ in
                    PlayfitGlassCard {
                        VStack(alignment: .leading, spacing: PlayfitSpacing.sm) {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.quaternary)
                                .aspectRatio(0.72, contentMode: .fit)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.quaternary)
                                .frame(height: 20)
                                .frame(maxWidth: 200)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.quaternary)
                                .frame(height: 14)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.quaternary)
                                .frame(height: 14)
                                .frame(maxWidth: 150)
                        }
                    }
                }
            }
            .redacted(reason: .placeholder)
        }
    }

    // MARK: - Error

    private func errorState(_ message: String) -> some View {
        VStack(spacing: PlayfitSpacing.sm) {
            Text("Play Next could not load")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: PlayfitSpacing.md) {
            VStack(spacing: PlayfitSpacing.sm) {
                Text("No games to recommend yet")
                    .font(.headline)
                Text("Try adding more platforms or rating more games so we can find a recommendation.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if !viewModel.excludedIds.isEmpty {
                Text("All current candidates were skipped in this session.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                Button("Show skipped again") {
                    viewModel.clearSkipped()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: - Primary Section

    private func primarySection(_ entry: RankedRecommendation) -> some View {
        VStack(alignment: .leading, spacing: PlayfitSpacing.lg) {
            header
            primaryCard(entry)
        }
    }

    // MARK: - Primary Card

    private func primaryCard(_ entry: RankedRecommendation) -> some View {
        PlayfitGlassCard {
            VStack(alignment: .leading, spacing: PlayfitSpacing.md) {
                PlayfitCoverPlaceholder(title: entry.game.title)

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: PlayfitSpacing.xs) {
                        Text("Play this next")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Text(entry.game.title)
                            .font(.title.bold())
                    }

                    Spacer()

                    ScoreBadge(score: Double(entry.affinityScore) / 100.0)
                }

                HStack(spacing: PlayfitSpacing.sm) {
                    DecisionLabelBadge(
                        label: decisionLabel(for: entry),
                        tone: decisionTone(for: entry)
                    )

                    NavigationLink {
                        GameDetailView(entry: entry)
                    } label: {
                        Text("See analysis")
                            .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.blue)
                }

                if !entry.fitReasons.isEmpty {
                    FitReasonsCard(title: "Why this fits", reasons: entry.fitReasons, tone: .positive)
                }

                let cautions = filterUsefulCautions(entry.cautionReasons)
                if !cautions.isEmpty {
                    FitReasonsCard(title: "Watch-outs", reasons: cautions, tone: .warning)
                }

                Button {
                    viewModel.addPick(entry)
                } label: {
                    Label(
                        viewModel.isPicked(entry.game.id) ? "Saved to Picks" : "Add to Playfit Picks",
                        systemImage: viewModel.isPicked(entry.game.id) ? "bookmark.fill" : "bookmark"
                    )
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isPicked(entry.game.id))

                if showReasonPicker {
                    FeedbackReasonPicker { reason in
                        viewModel.showToast("Noted: \(reason.lowercased()).")
                        showReasonPicker = false
                    }
                }

                HStack(spacing: PlayfitSpacing.md) {
                    Button {
                        selectedEntry = entry
                        showAlreadyPlayed = true
                    } label: {
                        Label("Already Played", systemImage: "checkmark.circle")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)

                    Button {
                        viewModel.notForMe(entry)
                        showReasonPicker = true
                    } label: {
                        Label("No, skip this", systemImage: "forward")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    viewModel.skip(entry)
                } label: {
                    Text("Show me another option")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showAlreadyPlayed) {
            if let entry = selectedEntry ?? viewModel.primary {
                AlreadyPlayedSheet { feedback in
                    viewModel.alreadyPlayed(entry, feedback: feedback)
                    showAlreadyPlayed = false
                    selectedEntry = nil
                    showReasonPicker = false
                }
            }
        }
    }

    // MARK: - Alternatives

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
            }
        }
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
}

// MARK: - Compact Row

private struct CompactRecommendationRow: View {
    let entry: RankedRecommendation

    var body: some View {
        PlayfitGlassCard {
            HStack(spacing: PlayfitSpacing.md) {
                PlayfitCoverPlaceholder(title: entry.game.title)
                    .frame(width: 76)

                VStack(alignment: .leading, spacing: PlayfitSpacing.xs) {
                    Text("Worth checking")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(entry.game.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(entry.game.genres.joined(separator: " / "))
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
    }
}
