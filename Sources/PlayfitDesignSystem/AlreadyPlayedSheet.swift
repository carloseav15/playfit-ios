import PlayfitModels
import SwiftUI

public struct AlreadyPlayedSheet: View {
    let onSelect: (AlreadyPlayedFeedback) -> Void

    public init(onSelect: @escaping (AlreadyPlayedFeedback) -> Void) {
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 4) {
                Text("Already Played")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text("How did it land?")
                    .font(.title2.bold())
            }
            .padding(.top)

            Text("Let us know how your experience was. This helps refine your future recommendations.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                optionButton("Loved it", icon: "heart.fill", color: .pink, feedback: .playedLoved)
                optionButton("Liked it", icon: "hand.thumbsup.fill", color: .blue, feedback: .playedLiked)
                optionButton("Mixed", icon: "ellipsis", color: .orange, feedback: .playedMixed)
                optionButton("Dropped", icon: "xmark", color: .gray, feedback: .playedDropped)
            }
        }
        .padding(24)
        .presentationDetents([.medium, .large])
    }

    private func optionButton(_ label: String, icon: String, color: Color, feedback: AlreadyPlayedFeedback) -> some View {
        Button {
            onSelect(feedback)
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(color)
                Text(label)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
