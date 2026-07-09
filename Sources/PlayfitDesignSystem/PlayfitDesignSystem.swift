import Foundation
import PlayfitModels
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public enum PlayfitSpacing {
    public static let xs: CGFloat = 6
    public static let sm: CGFloat = 10
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
}

public struct PlayfitGlassCard<Content: View>: View {
    @Environment(\.colorSchemeContrast) private var contrast
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
                    .stroke(.primary.opacity(contrast == .increased ? 0.28 : 0.12), lineWidth: 1)
            }
    }
}

private actor CoverImageLoader {
    static let shared = CoverImageLoader()
    private let memoryCache = NSCache<NSURL, NSData>()
    private let urlSession: URLSession

    private init() {
        memoryCache.totalCostLimit = 64 * 1_024 * 1_024
        let config = URLSessionConfiguration.default
        let cache = URLCache(
            memoryCapacity: 20 * 1024 * 1024,
            diskCapacity: 100 * 1024 * 1024,
            diskPath: "cover_images_cache"
        )
        config.urlCache = cache
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.urlSession = URLSession(configuration: config)
    }

    func data(for url: URL) async throws -> Data {
        if let cached = memoryCache.object(forKey: url as NSURL) {
            return cached as Data
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 20
        let (data, response) = try await urlSession.data(for: request)
        guard let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode),
              !data.isEmpty else {
            throw URLError(.badServerResponse)
        }
        memoryCache.setObject(data as NSData, forKey: url as NSURL, cost: data.count)
        return data
    }
}

public struct PlayfitGameCover: View {
    // The fixed portrait box every cover renders into (matches web's `aspect-[2/3]`-ish crop).
    private static let boxRatio: CGFloat = 0.75

    private let game: Game
    private let baseURL: URL
    @State private var image: Image?
    @State private var didFail = false

    public init(
        game: Game,
        baseURL: URL = URL(string: "https://playfit-gold.vercel.app")!
    ) {
        self.game = game
        self.baseURL = baseURL
    }

    public var body: some View {
        ZStack {
            if image == nil {
                if didFail || game.resolvedCoverURL(baseURL: baseURL) == nil {
                    coverFallback
                } else {
                    Rectangle().fill(.quaternary)
                    ProgressView().tint(.secondary)
                }
            }

            if let image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .aspectRatio(image != nil ? nil : Self.boxRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cover art for \(game.title)")
        .task(id: game.resolvedCoverURL(baseURL: baseURL)) {
            await loadImage()
        }
    }

    private var backdrop: some View {
        LinearGradient(
            colors: [Color.playfitIndigo, Color.playfitAccent, Color.black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var coverFallback: some View {
        ZStack {
            backdrop
            Image(systemName: "gamecontroller.fill")
                .font(.largeTitle)
                .foregroundStyle(.white.opacity(0.72))
        }
    }

    @MainActor
    private func loadImage() async {
        image = nil
        didFail = false
        guard let url = game.resolvedCoverURL(baseURL: baseURL) else {
            didFail = true
            return
        }
        do {
            let data = try await CoverImageLoader.shared.data(for: url)
            #if canImport(UIKit)
            guard let platformImage = UIImage(data: data) else { throw URLError(.cannotDecodeContentData) }
            image = Image(uiImage: platformImage)
            #elseif canImport(AppKit)
            guard let platformImage = NSImage(data: data) else { throw URLError(.cannotDecodeContentData) }
            image = Image(nsImage: platformImage)
            #endif
        } catch {
            didFail = true
        }
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
            .foregroundStyle(Color.playfitInkForeground)
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

public struct PlayfitGlowBackground: View {
    private let primaryOpacity: Double
    private let secondaryOpacity: Double
    private let compact: Bool

    public init(primaryOpacity: Double = 0.12, secondaryOpacity: Double = 0.08) {
        self.primaryOpacity = primaryOpacity
        self.secondaryOpacity = secondaryOpacity
        self.compact = false
    }

    private init(compact: Bool) {
        self.primaryOpacity = 0
        self.secondaryOpacity = 0
        self.compact = compact
    }

    public static var compact: PlayfitGlowBackground {
        PlayfitGlowBackground(compact: true)
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                if compact {
                    Circle()
                        .fill(Color.playfitAccent.opacity(0.12))
                        .frame(width: 260, height: 260)
                        .blur(radius: 60)
                        .position(x: geometry.size.width - 50, y: 80)
                } else {
                    Circle()
                        .fill(Color.playfitAccent.opacity(primaryOpacity))
                        .frame(width: 320, height: 320)
                        .blur(radius: 80)
                        .position(x: geometry.size.width - 50, y: 100)

                    Circle()
                        .fill(Color.playfitToneAccent.opacity(secondaryOpacity))
                        .frame(width: 280, height: 280)
                        .blur(radius: 70)
                        .position(x: 50, y: geometry.size.height - 150)
                }
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
        }
    }
}

