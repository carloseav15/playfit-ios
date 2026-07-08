import PlayfitDesignSystem
import PlayfitLogic
import PlayfitModels
import SwiftUI

public struct DecisionsActivityView: View {
    @Environment(\.playViewModel) private var viewModel
    @State private var activeTab: ActivityTab = .all
    @State private var signalToManage: TasteHistoryEntry?
    @State private var signalToChange: TasteHistoryEntry?

    public init() {}

    private enum ActivityTab {
        case all, active, taste
    }

    public var body: some View {
        let history = buildTasteHistoryEntries(
            gameStates: viewModel.gameStates,
            onboardingLikedIds: viewModel.onboardingLikedGameIds,
            onboardingDislikedIds: viewModel.onboardingDislikedGameIds,
            gamesCache: viewModel.gamesCache
        )

        let filtered = history.filter { entry in
            switch activeTab {
            case .all: true
            case .active: entry.decision == "picks"
            case .taste: entry.decision != "picks"
            }
        }

        ZStack {
            Color.playfitBackground.ignoresSafeArea()

            VStack(spacing: PlayfitSpacing.sm) {
                Picker("Activity Filters", selection: $activeTab) {
                    Text("All (\(history.count))").tag(ActivityTab.all)
                    Text("Picks (\(history.filter { $0.decision == "picks" }.count))").tag(ActivityTab.active)
                    Text("Preferences (\(history.filter { $0.decision != "picks" }.count))").tag(ActivityTab.taste)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                if filtered.isEmpty {
                    ContentUnavailableView("No ratings or activity matched this filter.", systemImage: "line.3.horizontal.decrease.circle")
                } else {
                    ScrollView {
                        LazyVStack(spacing: PlayfitSpacing.sm) {
                            ForEach(filtered, id: \.gameId) { entry in
                                ActivityRow(
                                    entry: entry,
                                    game: viewModel.gamesCache[entry.gameId],
                                    onManage: { signalToManage = entry }
                                )
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.syncIfOnline()
                    }
                }
            }
        }
        .confirmationDialog(
            "Manage Signal",
            isPresented: Binding(
                get: { signalToManage != nil },
                set: { if !$0 { signalToManage = nil } }
            ),
            titleVisibility: .visible
        ) {
            manageSignalButtons
        } message: {
            if let entry = signalToManage {
                Text("Choose an action for \(entry.title)")
            }
        }
        .sheet(item: $signalToChange) { entry in
            ChangeSignalSheet(title: entry.title) { feedback in
                viewModel.updateSignal(gameId: entry.gameId, feedback: feedback)
            }
        }
    }

    @ViewBuilder
    private var manageSignalButtons: some View {
        if let entry = signalToManage {
            if entry.decision == "picks" {
                Button("Remove from Picks", role: .destructive) {
                    viewModel.removePick(entry.gameId)
                    signalToManage = nil
                }
            } else {
                Button("Change Signal") {
                    signalToChange = entry
                    signalToManage = nil
                }
                Button("Delete Signal", role: .destructive) {
                    viewModel.deleteSignal(entry.gameId, source: entry.source)
                    signalToManage = nil
                }
            }

            Button("Cancel", role: .cancel) {
                signalToManage = nil
            }
        }
    }
}
