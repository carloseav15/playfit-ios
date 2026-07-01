import PlayfitDesignSystem
import PlayfitLogic
import PlayfitModels
import SwiftUI

public struct GameDetailView: View {
    @Environment(\.playViewModel) private var viewModel
    let entry: RankedRecommendation
    @State private var showAlreadyPlayed = false

    public init(entry: RankedRecommendation) {
        self.entry = entry
    }

    public var body: some View {
        ZStack {
            Color.playfitBackground.ignoresSafeArea()
            
            glowBackground
            
            ScrollView {
            VStack(alignment: .leading, spacing: PlayfitSpacing.lg) {
                PlayfitCoverPlaceholder(title: entry.game.title)
                    .frame(maxWidth: 260)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: PlayfitSpacing.sm) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: PlayfitSpacing.xs) {
                            Text(entry.game.title)
                                .font(.largeTitle.bold())

                            if let year = entry.game.releaseYear {
                                Text(year)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        ScoreBadge(score: Double(entry.affinityScore) / 100.0)
                    }

                    HStack(spacing: PlayfitSpacing.sm) {
                        Text("Recommended")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.12), in: Capsule())

                        DecisionLabelBadge(
                            label: decisionLabel(for: entry),
                            tone: decisionTone(for: entry)
                        )
                    }

                    if !entry.game.primaryGenre.isEmpty {
                        Text(entry.game.primaryGenre)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

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

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: PlayfitSpacing.sm) {
                    RecommendationMetric(
                        label: "Match Affinity",
                        value: "\(entry.affinityScore)%",
                        numericValue: entry.affinityScore,
                        color: Color.playfitAccent
                    )
                    RecommendationMetric(
                        label: "Watch-out Score",
                        value: "\(entry.riskScore)%",
                        numericValue: entry.riskScore,
                        color: entry.riskScore > 45 ? .red : .orange
                    )
                    RecommendationMetric(
                        label: "Confidence Read",
                        value: confidenceLabel(entry.confidence),
                        color: Color.playfitAccent
                    )
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
            }
            .padding(PlayfitSpacing.md)
        }
        }
        .navigationTitle(entry.game.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .safeAreaInset(edge: .bottom) {
            dossierActions
        }
        .sheet(isPresented: $showAlreadyPlayed) {
            AlreadyPlayedSheet { feedback in
                viewModel.alreadyPlayed(entry, feedback: feedback)
                showAlreadyPlayed = false
            }
        }
    }

    private var dossierActions: some View {
        HStack(spacing: PlayfitSpacing.md) {
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

            Button {
                showAlreadyPlayed = true
            } label: {
                Label("Already played", systemImage: "checkmark.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                viewModel.notForMe(entry)
            } label: {
                Label("Not for me", systemImage: "xmark.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding(PlayfitSpacing.md)
        .background(.regularMaterial)
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
