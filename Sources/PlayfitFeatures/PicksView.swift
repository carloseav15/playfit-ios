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
            
            glowBackground
            
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
        .confirmationDialog(
            "Manage Pick",
            isPresented: Binding(
                get: { manageEntry != nil && !showAlreadyPlayed },
                set: { if !$0 && !showAlreadyPlayed { manageEntry = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Already Played It") { showAlreadyPlayed = true }
            Button("No, skip this", role: .destructive) {
                if let entry = manageEntry { viewModel.notForMe(entry) }
                manageEntry = nil
            }
            Button("Remove Pick", role: .destructive) {
                if let entry = manageEntry { viewModel.removePick(entry.game.id) }
                manageEntry = nil
            }
            Button("Cancel", role: .cancel) { manageEntry = nil }
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
