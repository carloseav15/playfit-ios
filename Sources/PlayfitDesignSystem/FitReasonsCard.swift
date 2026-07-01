import PlayfitModels
import SwiftUI

public struct FitReasonsCard: View {
    let title: String
    let reasons: [String]
    let tone: DecisionTone

    public init(title: String, reasons: [String], tone: DecisionTone) {
        self.title = title
        self.reasons = reasons
        self.tone = tone
    }

    private var tint: Color {
        switch tone {
        case .positive: .green
        case .warning: .yellow
        case .negative: .red
        case .info: .blue
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .textCase(.uppercase)

            ForEach(reasons.prefix(4), id: \.self) { reason in
                HStack(spacing: 6) {
                    Circle()
                        .fill(tint)
                        .frame(width: 6, height: 6)
                    Text(reason)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
