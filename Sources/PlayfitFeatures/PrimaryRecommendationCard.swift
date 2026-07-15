import PlayfitDesignSystem
import PlayfitLogic
import PlayfitModels
import SwiftUI

struct PrimaryRecommendationCard: View {
    @Environment(\.playViewModel) private var viewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let entry: RankedRecommendation
    @Binding var selectedEntry: RankedRecommendation?
    @Binding var showAlreadyPlayed: Bool
    @State private var decisionHapticTrigger = false

    private var cardSwapAnimation: Animation? {
        reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)
    }

    var body: some View {
        PlayfitGlassCard {
            VStack(alignment: .leading, spacing: PlayfitSpacing.md) {
                PlayfitGameCover(game: entry.game)
                header
                badges
                reasons
                pickButton
                actionButtons
                skipButton
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: decisionHapticTrigger)
        .sheet(isPresented: $showAlreadyPlayed) {
            if let entry = selectedEntry ?? viewModel.primary {
                AlreadyPlayedSheet { feedback in
                    withAnimation(cardSwapAnimation) {
                        viewModel.alreadyPlayed(entry, feedback: feedback)
                    }
                    showAlreadyPlayed = false
                    selectedEntry = nil
                }
            }
        }
    }

    private var header: some View {
        let headerLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: PlayfitSpacing.sm))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
        return headerLayout {
            VStack(alignment: .leading, spacing: PlayfitSpacing.xs) {
                Text("Play this next")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(entry.game.title)
                    .font(.title.bold())
            }

            if !dynamicTypeSize.isAccessibilitySize {
                Spacer()
            }

            ScoreBadge(score: Double(entry.affinityScore) / 100.0)
        }
    }

    private var badges: some View {
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
            .accessibilityLabel("See analysis for \(entry.game.title)")
            .foregroundStyle(Color.playfitAccent)
        }
    }

    @ViewBuilder
    private var reasons: some View {
        if !entry.fitReasons.isEmpty {
            FitReasonsCard(title: "Why this fits", reasons: entry.fitReasons, tone: .positive)
        }

        let cautions = filterUsefulCautions(entry.cautionReasons)
        if !cautions.isEmpty {
            FitReasonsCard(title: "Watch-outs", reasons: cautions, tone: .warning)
        }
    }

    private var pickButton: some View {
        Button {
            viewModel.addPick(entry)
        } label: {
            Label(
                viewModel.isPicked(entry.game.id) ? "Saved to Picks" : "Save to Picks",
                systemImage: viewModel.isPicked(entry.game.id) ? "bookmark.fill" : "bookmark"
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(viewModel.isPicked(entry.game.id) ? AnyShapeStyle(.secondary) : AnyShapeStyle(.white))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        viewModel.isPicked(entry.game.id)
                            ? AnyShapeStyle(Color.secondary.opacity(0.15))
                            : colorScheme == .dark
                                ? AnyShapeStyle(LinearGradient(colors: [.playfitAccent, .playfitIndigo], startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(Color.playfitAccent)
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.isPicked(entry.game.id) ? "Saved to Picks" : "Save to Picks")
        .disabled(viewModel.isPicked(entry.game.id))
    }

    private var actionButtons: some View {
        let actionLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: PlayfitSpacing.sm))
            : AnyLayout(HStackLayout(spacing: PlayfitSpacing.md))
        return actionLayout {
            Button {
                selectedEntry = entry
                showAlreadyPlayed = true
            } label: {
                Label("Already Played", systemImage: "checkmark.circle")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Mark \(entry.game.title) as Already Played")
            .tint(.playfitPositive)

            Button {
                withAnimation(cardSwapAnimation) {
                    viewModel.notForMe(entry)
                }
                decisionHapticTrigger.toggle()
            } label: {
                Label("No, skip this", systemImage: "forward")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Mark \(entry.game.title) as Not For Me")
            .tint(.playfitNegative)
        }
    }

    private var skipButton: some View {
        Button {
            withAnimation(cardSwapAnimation) {
                viewModel.skip(entry)
            }
            decisionHapticTrigger.toggle()
        } label: {
            Text("Show me another option")
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show me another option instead of \(entry.game.title)")
        .foregroundStyle(.secondary)
    }
}
