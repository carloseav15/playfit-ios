import PlayfitDesignSystem
import SwiftUI

struct ChangeSignalSheet: View {
    let title: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var decisionHapticTrigger = false

    var body: some View {
        ZStack {
            Color.playfitBackground.ignoresSafeArea()

            VStack(spacing: PlayfitSpacing.md) {
                HStack {
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.playfitAccent)
                }
                .padding(.horizontal)
                .padding(.top, 16)

                VStack(alignment: .leading, spacing: 4) {
                    Text("How did it land?")
                        .font(.title3.weight(.black))
                    Text("Update your taste footprint for \(title)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                VStack(spacing: PlayfitSpacing.sm) {
                    optionRow(label: "Loved", sub: "Excellent gameplay and loop", icon: "heart.fill", color: .playfitPositive, val: "played_loved")
                    optionRow(label: "Liked", sub: "Solid experience worth playing", icon: "hand.thumbsup.fill", color: .playfitPositive, val: "played_liked")
                    optionRow(label: "Mixed", sub: "Good elements but had issues", icon: "waveform", color: .playfitWarning, val: "played_mixed")
                    optionRow(label: "Dropped", sub: "Lost interest or didn't finish", icon: "hand.thumbsdown.fill", color: .playfitNegative, val: "played_dropped")
                    optionRow(label: "Not For Me", sub: "Avoid recommending similar games", icon: "xmark.octagon.fill", color: .playfitNegative, val: "not_for_me")
                }
                .padding()

                Spacer()
            }
        }
        .presentationDetents([.medium, .large])
        .sensoryFeedback(.impact(weight: .medium), trigger: decisionHapticTrigger)
    }

    private func optionRow(label: String, sub: String, icon: String, color: Color, val: String) -> some View {
        Button {
            onSelect(val)
            decisionHapticTrigger.toggle()
            dismiss()
        } label: {
            HStack(spacing: PlayfitSpacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Text(sub)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.4))
            }
            .padding(10)
            .background(Color.primary.opacity(0.02), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label): \(sub)")
    }
}
