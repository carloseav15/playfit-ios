import SwiftUI

public struct RecommendationMetric: View {
    let label: String
    let value: String
    let detail: String?
    let numericValue: Int?
    let color: Color

    public init(
        label: String,
        value: String,
        detail: String? = nil,
        numericValue: Int? = nil,
        color: Color = .playfitInk
    ) {
        self.label = label
        self.value = value
        self.detail = detail
        self.numericValue = numericValue
        self.color = color
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(value)
                .font(.callout.weight(.bold))
                .foregroundStyle(.primary)

            if let detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if let numericValue {
                ProgressView(value: Double(numericValue) / 100.0)
                    .tint(color)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
