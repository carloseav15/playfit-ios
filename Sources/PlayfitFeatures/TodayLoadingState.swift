import PlayfitDesignSystem
import SwiftUI

struct TodayLoadingState: View {
    let slowLoading: Bool

    var body: some View {
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
}
