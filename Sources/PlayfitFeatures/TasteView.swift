import PlayfitDesignSystem
import PlayfitModels
import PlayfitLogic
import SwiftUI

public struct TasteView: View {
    @Environment(\.playViewModel) private var viewModel
    @State private var activeTab: TasteTab = .yourTaste

    private enum TasteTab: Hashable {
        case yourTaste, activity
    }

    public init() {}

    public var body: some View {
        let history = buildTasteHistoryEntries(
            gameStates: viewModel.gameStates,
            onboardingLikedIds: [], // Onboarding preferences are already in cache
            onboardingDislikedIds: [],
            gamesCache: viewModel.gamesCache
        )

        let likedCount = history.filter { $0.tone == "positive" }.count
        let avoidedCount = history.filter { $0.tone == "negative" }.count

        ZStack {
            Color.playfitBackground.ignoresSafeArea()

            glowBackground

            VStack(spacing: 0) {
                Picker("Taste Sections", selection: $activeTab) {
                    Text("Your Taste").tag(TasteTab.yourTaste)
                    Text("Activity").tag(TasteTab.activity)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, PlayfitSpacing.md)
                .padding(.top, PlayfitSpacing.sm)

                switch activeTab {
                case .yourTaste:
                    yourTasteTab(history: history, likedCount: likedCount, avoidedCount: avoidedCount)
                case .activity:
                    DecisionsActivityView()
                }
            }

            if viewModel.isLoading {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.playfitAccent)
                    .controlSize(.large)
            }
        }
        .navigationTitle("My Taste")
        .task {
            await viewModel.hydrateTasteGames()
        }
    }

    private func yourTasteTab(history: [TasteHistoryEntry], likedCount: Int, avoidedCount: Int) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PlayfitSpacing.lg) {

                // Onboarding Calibration Warning
                if viewModel.profile.ratedCount < 4 {
                    Text("Add at least 3 liked games and 1 missed game to refine your recommendations.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.yellow.opacity(0.25), lineWidth: 1)
                        )
                }

                // Profile Summary Card
                PlayfitGlassCard {
                    VStack(alignment: .leading, spacing: PlayfitSpacing.xs) {
                        HStack(spacing: 6) {
                            Image(systemName: "shield.fill")
                                .foregroundColor(.playfitAccent)
                                .font(.caption)
                            Text("Profile Summary")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.playfitAccent)
                                .textCase(.uppercase)
                        }

                        Text(likedCount > avoidedCount
                             ? "Playfit leans toward your favorites, but still needs more signals to sharpen the edge cases."
                             : "Playfit is still balancing your likes and misses; a few more decisions will make the next pick steadier.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(2.5)
                            .padding(.top, 4)
                    }
                    .padding()
                }

                // Stats Summary Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: PlayfitSpacing.sm), count: 3), spacing: PlayfitSpacing.sm) {
                    statCard("Preferences", "\(viewModel.profile.ratedCount)")
                    statCard("Liked", "\(likedCount)")
                    statCard("Avoided", "\(avoidedCount)")
                }

                TasteMapVisualizerView()
                    .frame(minHeight: 560)
                    .padding(.top, 4)
            }
            .padding(PlayfitSpacing.md)
        }
    }

    private func statCard(_ label: String, _ value: String) -> some View {
        PlayfitGlassCard {
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundColor(.primary)
                Text(label)
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    private var glowBackground: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(Color.playfitAccent.opacity(0.10))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .position(x: geometry.size.width - 50, y: 100)

                Circle()
                    .fill(Color.playfitToneAccent.opacity(0.06))
                    .frame(width: 280, height: 280)
                    .blur(radius: 70)
                    .position(x: 50, y: geometry.size.height - 150)
            }
            .ignoresSafeArea()
        }
    }
}
