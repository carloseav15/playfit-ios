import PlayfitDesignSystem
import SwiftUI

struct SignInSheetHeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: PlayfitSpacing.xs) {
            Text("PLAYFIT DECISIONS")
                .font(.caption2.monospaced().weight(.black))
                .foregroundColor(.playfitAccent)
                .tracking(2.5)
                .padding(.top, 16)

            Text(title)
                .font(.system(.title, design: .rounded).weight(.black))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .lineSpacing(2)
        }
        .padding(.bottom, 8)
    }
}
