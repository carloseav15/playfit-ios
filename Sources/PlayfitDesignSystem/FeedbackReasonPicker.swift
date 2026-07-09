import SwiftUI

public struct FeedbackReasonPicker: View {
    let onSelect: (String) -> Void

    public init(onSelect: @escaping (String) -> Void) {
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What got in the way?")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                reasonButton("Wrong mood")
                reasonButton("Too long")
                reasonButton("Too hard")
                reasonButton("Not my genre")
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func reasonButton(_ reason: String) -> some View {
        Button {
            onSelect(reason)
        } label: {
            Text(reason)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(.thinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(reason)
    }
}
