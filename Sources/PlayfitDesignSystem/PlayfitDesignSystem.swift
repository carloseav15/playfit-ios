import PlayfitModels
import SwiftUI

public enum PlayfitSpacing {
    public static let xs: CGFloat = 6
    public static let sm: CGFloat = 10
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
}

public struct PlayfitGlassCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(PlayfitSpacing.md)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            }
    }
}

public struct PlayfitCoverPlaceholder: View {
    private let title: String

    public init(title: String) {
        self.title = title
    }

    public var body: some View {
        let filename = title.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "’", with: "")
            .replacingOccurrences(of: "•", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let url = URL(string: "https://playfit-gold.vercel.app/covers/games/\(filename).jpg")

        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            default:
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [.indigo, .purple, .black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Text(title)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .padding(8)
                }
            }
        }
        .aspectRatio(0.72, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
    }
}

public struct ScoreBadge: View {
    private let score: Double

    public init(score: Double) {
        self.score = score
    }

    public var body: some View {
        Text("\(Int((score * 100).rounded()))% fit")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.playfitInk, in: Capsule())
    }
}

public struct DecisionLabelBadge: View {
    private let label: String
    private let tone: DecisionTone

    public init(label: String, tone: DecisionTone) {
        self.label = label
        self.tone = tone
    }

    public var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(toneForeground)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(toneBackground, in: Capsule())
    }

    private var toneForeground: Color {
        switch tone {
        case .positive: .playfitPositive
        case .warning: .playfitWarning
        case .negative: .playfitNegative
        case .info: .playfitToneAccent
        }
    }

    private var toneBackground: Color {
        switch tone {
        case .positive: .playfitPositive.opacity(0.15)
        case .warning: .playfitWarning.opacity(0.15)
        case .negative: .playfitNegative.opacity(0.15)
        case .info: .playfitToneAccent.opacity(0.15)
        }
    }
}

public struct TokenRow: View {
    private let values: [String]

    public init(_ values: [String]) {
        self.values = values
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PlayfitSpacing.xs) {
                ForEach(values, id: \.self) { value in
                    Text(value)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.thinMaterial, in: Capsule())
                }
            }
        }
    }
}
