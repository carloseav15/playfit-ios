import PlayfitDesignSystem
import PlayfitModels
import SwiftUI

struct ActivityRow: View {
    let entry: TasteHistoryEntry
    let game: Game?
    let onManage: () -> Void

    var body: some View {
        HStack(spacing: PlayfitSpacing.md) {
            NavigationLink {
                GameDetailView(gameId: entry.gameId)
            } label: {
                HStack(spacing: PlayfitSpacing.md) {
                    cover
                    details
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            Button(action: onManage) {
                Image(systemName: "ellipsis")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Manage \(entry.title)")
        }
        .padding(12)
        .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var cover: some View {
        if let game {
            PlayfitGameCover(game: game)
                .frame(width: 44, height: 60)
                .cornerRadius(8)
        } else {
            Color.primary.opacity(0.04)
                .frame(width: 44, height: 60)
                .cornerRadius(8)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(entry.activityBadgeLabel)
                    .font(.caption2.weight(.black))
                    .foregroundColor(entry.activityBadgeColor)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(entry.activityBadgeColor.opacity(0.10), in: Capsule())

                if let rating = entry.rating, rating > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption2)
                        Text(String(format: "%.0f", rating))
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                    }
                }
            }

            Text(entry.title)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
                .lineLimit(1)

            Text(entry.activityDateLabel)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
