import PlayfitDesignSystem
import PlayfitModels
import SwiftUI

public struct DecisionIntroView: View {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @Environment(\.colorScheme) private var colorScheme

    let onStart: () -> Void
    let onSignIn: () -> Void

    public init(onStart: @escaping () -> Void, onSignIn: @escaping () -> Void) {
        self.onStart = onStart
        self.onSignIn = onSignIn
    }

    public var body: some View {
        ZStack {
            Color.playfitBackground.ignoresSafeArea()
            
            PlayfitGlowBackground()
            
            ScrollView {
                VStack(spacing: PlayfitSpacing.lg) {
                    heroSection
                    previewCard
                }
                .padding(PlayfitSpacing.md)
            }
        }
        .foregroundStyle(Color.playfitForeground)
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: PlayfitSpacing.lg) {
            HStack {
                HStack(spacing: PlayfitSpacing.sm) {
                    Image("playfit_logo", bundle: Bundle.main)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )

                    Text("Playfit")
                        .font(.caption.weight(.black))
                        .foregroundColor(.playfitAccent)
                        .tracking(3)
                }

                Spacer()

                themePickerButton
            }

            VStack(alignment: .leading, spacing: PlayfitSpacing.md) {
                (
                    Text("Your next game, ")
                        .font(.largeTitle.weight(.black))
                        .foregroundColor(Color.playfitForeground)
                    + Text("curated.")
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.playfitAccent, Color.pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .tracking(-0.5)
                .lineSpacing(-2)

                Text("Select your platforms, three favorites, and one notable miss. Get one clear recommendation with its complete decision analysis.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)

                Text("Zero noise. Zero decision fatigue.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: PlayfitSpacing.sm) {
                Button(action: onStart) {
                    Label("Find What to Play", systemImage: "safari")
                        .font(.headline.weight(.black))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: colorScheme == .dark ? [Color.playfitAccent, Color.playfitIndigo] : [Color.playfitAccent, Color.playfitAccent.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .shadow(
                            color: colorScheme == .dark ? Color.playfitAccent.opacity(0.25) : Color.playfitAccent.opacity(0.35),
                            radius: colorScheme == .dark ? 15 : 10,
                            x: 0,
                            y: colorScheme == .dark ? 6 : 4
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("playfit.intro.start")

                Button(action: onSignIn) {
                    Label("Sign In", systemImage: "arrow.right")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(Color.playfitForeground)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("playfit.intro.signin")
            }
        }
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: PlayfitSpacing.md) {
            HStack {
                Label("Playfit Curation", systemImage: "sparkles")
                    .font(.caption2.weight(.black))
                    .foregroundColor(.playfitAccent)
                    .tracking(2)

                Spacer()

                Text("94% Vibe Fit")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.playfitAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.playfitAccent.opacity(0.1), in: Capsule())
                    .overlay(Capsule().stroke(Color.playfitAccent.opacity(0.3), lineWidth: 1))
            }

            HStack(spacing: PlayfitSpacing.md) {
                PlayfitGameCover(
                    game: Game(
                        id: "hades",
                        title: "Hades",
                        coverPath: "/covers/games/hades.jpg"
                    )
                )
                    .frame(width: 72)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Action • Roguelike")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.secondary)
                        .tracking(1)

                    Text("Hades")
                        .font(.title3.weight(.black))
                        .foregroundStyle(Color.playfitForeground)

                    Text("Defy the god of the dead in a hack-and-slash underworld escape.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Divider()

            VStack(spacing: PlayfitSpacing.xs) {
                reasonRow(
                    label: "Why it matches",
                    value: "High action affinity",
                    dotColor: .green
                )
                reasonRow(
                    label: "Watch-outs",
                    value: "Repetitive run loops",
                    dotColor: .orange
                )
                reasonRow(
                    label: "Confidence",
                    value: nil,
                    dotColor: .playfitAccent,
                    badge: "High"
                )
            }
        }
        .padding(PlayfitSpacing.md)
        .background(
            ZStack {
                Color.clear
                // Glowing aura inside card (matching web)
                GeometryReader { geo in
                    Circle()
                        .fill(Color.playfitAccent.opacity(0.18))
                        .frame(width: 140, height: 140)
                        .blur(radius: 25)
                        .position(x: geo.size.width - 20, y: 20)
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.25), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    private func reasonRow(label: String, value: String?, dotColor: Color, badge: String? = nil) -> some View {
        HStack {
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            if let badge {
                Text(badge)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.regularMaterial, in: Capsule())
            }

            if let value {
                Text(value)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
    }

    private var themePickerButton: some View {
        Menu {
            Picker("Appearance", selection: $appearanceMode) {
                Label("Light", systemImage: "sun.max").tag(AppearanceMode.light)
                Label("Dark", systemImage: "moon").tag(AppearanceMode.dark)
                Label("System", systemImage: "gearshape").tag(AppearanceMode.system)
            }
        } label: {
            Image(systemName: appearanceModeIcon)
                .font(.body.weight(.bold))
                .foregroundColor(.secondary)
                .padding(10)
                .background(.regularMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private var appearanceModeIcon: String {
        switch appearanceMode {
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        case .system: "circle.lefthalf.striped.horizontal"
        }
    }
}
