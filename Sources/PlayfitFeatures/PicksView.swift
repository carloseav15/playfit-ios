import PlayfitDesignSystem
import PlayfitModels
import SwiftUI

public struct PicksView: View {
    @Environment(\.playViewModel) private var viewModel
    @State private var manageEntry: RankedRecommendation?
    @State private var showAlreadyPlayed = false

    public init() {}

    public var body: some View {
        let picks = viewModel.picks
        ZStack {
            Color.playfitBackground.ignoresSafeArea()
            
            PlayfitGlowBackground()
            
            List {
                if picks.isEmpty {
                    ContentUnavailableView(
                        "No saved picks yet",
                        systemImage: "bookmark",
                        description: Text("Save recommendations here when they match your gaming criteria.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(picks) { entry in
                        PickRowView(
                            entry: entry,
                            manageAction: { manageEntry = entry }
                        )
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.removePick(entry.game.id)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .refreshable {
                await viewModel.syncIfOnline()
            }
        }
        .navigationTitle("Saved Picks")
        .sheet(isPresented: Binding(
            get: { manageEntry != nil && !showAlreadyPlayed },
            set: { if !$0 && !showAlreadyPlayed { manageEntry = nil } }
        )) {
            if let entry = manageEntry {
                ManagePickSheet(
                    title: entry.game.title,
                    onAlreadyPlayed: { showAlreadyPlayed = true },
                    onNotForMe: {
                        viewModel.notForMe(entry)
                        manageEntry = nil
                    },
                    onRemove: {
                        viewModel.removePick(entry.game.id)
                        manageEntry = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showAlreadyPlayed) {
            if let entry = manageEntry {
                AlreadyPlayedSheet { feedback in
                    viewModel.alreadyPlayed(entry, feedback: feedback)
                    showAlreadyPlayed = false
                    manageEntry = nil
                }
            }
        }
    }

}

// MARK: - Pick Row

private struct PickRowView: View {
    let entry: RankedRecommendation
    let manageAction: () -> Void

    var body: some View {
        HStack {
            NavigationLink {
                GameDetailView(entry: entry)
            } label: {
                HStack(spacing: PlayfitSpacing.md) {
                    PlayfitGameCover(game: entry.game)
                        .frame(width: 56)

                    VStack(alignment: .leading, spacing: PlayfitSpacing.xs) {
                        Text(entry.game.title)
                            .font(.headline)
                    }

                    Spacer()

                    Text("\(entry.affinityScore)% Match")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.playfitAccent)
                }
            }
            .buttonStyle(.plain)

            Button(action: manageAction) {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Manage \(entry.game.title)")
        }
    }
}

// MARK: - Manage Pick Sheet

private struct ManagePickSheet: View {
    let title: String
    let onAlreadyPlayed: () -> Void
    let onNotForMe: () -> Void
    let onRemove: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.playfitBackground.ignoresSafeArea()

            VStack(spacing: PlayfitSpacing.md) {
                HStack {
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(.subheadline.bold())
                        .foregroundColor(.playfitAccent)
                }
                .padding(.horizontal)
                .padding(.top, 16)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Manage Pick")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Text(title)
                        .font(.title3.weight(.black))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                VStack(spacing: PlayfitSpacing.sm) {
                    optionRow(
                        label: "Already Played",
                        icon: "checkmark.circle.fill",
                        color: .playfitPositive
                    ) {
                        // No explicit dismiss(): the parent's `isPresented` binding for
                        // this sheet already includes `!showAlreadyPlayed`, so setting
                        // that (inside onAlreadyPlayed) closes this sheet and opens the
                        // Already Played one in one step, instead of racing two dismissals.
                        onAlreadyPlayed()
                    }
                    optionRow(
                        label: "No, skip this",
                        icon: "xmark.circle.fill",
                        color: .playfitNegative
                    ) {
                        onNotForMe()
                        dismiss()
                    }
                    optionRow(
                        label: "Remove Pick",
                        icon: "trash.fill",
                        color: .playfitNegative
                    ) {
                        onRemove()
                        dismiss()
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
        .presentationDetents([.medium])
    }

    private func optionRow(label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: PlayfitSpacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

                Text(label)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(PlayfitSpacing.md)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
