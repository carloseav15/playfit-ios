import PlayfitDesignSystem
import SwiftUI

struct TodayEmptyState: View {
    @Environment(\.playViewModel) private var viewModel
    @Binding var showPlatformsSheet: Bool

    var body: some View {
        VStack(spacing: PlayfitSpacing.md) {
            VStack(spacing: PlayfitSpacing.sm) {
                Text("No games to recommend yet")
                    .font(.headline)
                Text("Try adding more platforms or rating more games so we can find a recommendation.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Add Platforms") {
                showPlatformsSheet = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.playfitAccent)
            .accessibilityLabel("Add Platforms")
            .sheet(isPresented: $showPlatformsSheet) {
                NavigationStack {
                    PlatformSelectionView()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showPlatformsSheet = false }
                                    .accessibilityLabel("Done")
                            }
                        }
                }
            }
            if !viewModel.excludedIds.isEmpty {
                Text("All current candidates were skipped in this session.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                Button("Show skipped again") {
                    Task { await viewModel.showSkippedAgain() }
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Show skipped again")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}
