import PlayfitDesignSystem
import PlayfitModels
import PlayfitLogic
import SwiftUI

public struct TasteView: View {
    @Environment(\.playViewModel) private var viewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var activeTab: TasteTab = .yourTaste

    private enum TasteTab: Hashable {
        case yourTaste, activity
    }

    public init() {}

    public var body: some View {
        let history = buildTasteHistoryEntries(
            gameStates: viewModel.gameStates,
            onboardingLikedIds: viewModel.onboardingLikedGameIds,
            onboardingDislikedIds: viewModel.onboardingDislikedGameIds,
            gamesCache: viewModel.gamesCache
        )

        let likedCount = history.filter { $0.tone == "positive" }.count
        let avoidedCount = history.filter { $0.tone == "negative" }.count
        let traits = buildTasteMapTraits(historyEntries: history, profile: viewModel.profile)

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
                    yourTasteTab(
                        history: history,
                        traits: traits,
                        likedCount: likedCount,
                        avoidedCount: avoidedCount
                    )
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

    private func yourTasteTab(
        history: [TasteHistoryEntry],
        traits: [TasteMapTrait],
        likedCount: Int,
        avoidedCount: Int
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PlayfitSpacing.lg) {

                // Onboarding Calibration Warning
                if viewModel.onboardingLikedGameIds.count < 3 || viewModel.onboardingDislikedGameIds.isEmpty {
                    Text("Select a few more favorite games so we can sharpen your recommendations.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.playfitWarning.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.playfitWarning.opacity(0.25), lineWidth: 1)
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

                        Text(viewModel.profile.summary.isEmpty
                             ? "Playfit is still learning from your decisions."
                             : viewModel.profile.summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(2.5)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }

                // Stats Summary Grid
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: PlayfitSpacing.sm),
                        count: dynamicTypeSize.isAccessibilitySize ? 1 : 3
                    ),
                    spacing: PlayfitSpacing.sm
                ) {
                    statCard("Signals", history.isEmpty ? "—" : "\(history.count)")
                    statCard("Liked", likedCount == 0 ? "—" : "\(likedCount)", tint: .playfitPositive)
                    statCard("Avoided", avoidedCount == 0 ? "—" : "\(avoidedCount)", tint: .playfitNegative)
                }

                VStack(alignment: .leading, spacing: PlayfitSpacing.sm) {
                    NavigationLink {
                        TasteMapVisualizerView()
                    } label: {
                        tasteMenuRow(
                            icon: "chart.dots.scatter",
                            title: "Interactive Affinity Map",
                            subtitle: "Visual graph of your gaming traits."
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        TasteTraitsListView(traits: traits)
                    } label: {
                        tasteMenuRow(
                            icon: "list.bullet.clipboard",
                            title: "Traits List",
                            subtitle: "An accessible text view of the evidence shown in the map."
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(PlayfitSpacing.md)
        }
        .refreshable {
            await viewModel.syncIfOnline()
            await viewModel.hydrateTasteGames()
        }
    }

    private func tasteMenuRow(icon: String, title: String, subtitle: String) -> some View {
        PlayfitGlassCard {
            HStack(spacing: PlayfitSpacing.md) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(.playfitAccent)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(PlayfitSpacing.md)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private func statCard(_ label: String, _ value: String, tint: Color? = nil) -> some View {
        PlayfitGlassCard {
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundColor(tint ?? .primary)
                Text(label)
                    .font(.caption2.bold())
                    .foregroundColor(tint ?? .secondary)
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

private struct TasteTraitsListView: View {
    let traits: [TasteMapTrait]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PlayfitSpacing.sm) {
                Text("An accessible text view of the evidence shown in the map.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if traits.isEmpty {
                    ContentUnavailableView(
                        "No traits yet",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Add or rate games to build your taste traits.")
                    )
                } else {
                    ForEach(traits) { trait in
                        PlayfitGlassCard {
                            HStack(spacing: PlayfitSpacing.md) {
                                Image(systemName: trait.direction == "positive" ? "arrow.up.right" : "arrow.down.right")
                                    .foregroundStyle(trait.direction == "positive" ? Color.playfitPositive : Color.playfitNegative)
                                    .frame(width: 28, height: 28)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(trait.label).font(.headline)
                                    Text("\(trait.kind.capitalized) · \(confidenceLabel(trait.confidence))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 3) {
                                    Text("\(Int(trait.strength))%")
                                        .font(.headline.monospacedDigit())
                                    Text("+\(trait.positiveCount) / −\(trait.negativeCount)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(PlayfitSpacing.md)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(
                                "\(trait.label), \(trait.direction), strength \(Int(trait.strength)) percent, \(trait.positiveCount) positive and \(trait.negativeCount) negative signals"
                            )
                        }
                    }
                }
            }
            .padding(PlayfitSpacing.md)
        }
        .background(Color.playfitBackground.ignoresSafeArea())
        .navigationTitle("Traits List")
    }
}
