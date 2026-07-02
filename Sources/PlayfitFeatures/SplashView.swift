import PlayfitDesignSystem
import SwiftUI

/// A brief branded animation shown right after the system launch screen hands off
/// to the app. iOS launch screens (`UILaunchScreen`) cannot animate — they must
/// render instantly and synchronously — so this view is what actually animates,
/// for a fixed, minimum duration, before `PlayfitRootView` shows real content.
struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onFinished: () -> Void

    @State private var logoScale: CGFloat = 0.82
    @State private var logoOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var titleOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.playfitBackground.ignoresSafeArea()

            Circle()
                .fill(Color.playfitAccent.opacity(0.25))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .opacity(glowOpacity)

            VStack(spacing: PlayfitSpacing.md) {
                Image("playfit_logo", bundle: Bundle.main)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Text("Playfit")
                    .font(.system(.title2, design: .rounded).weight(.black))
                    .foregroundStyle(.primary)
                    .opacity(titleOpacity)
            }
        }
        .task {
            if reduceMotion {
                logoScale = 1
                logoOpacity = 1
                glowOpacity = 1
                titleOpacity = 1
                try? await Task.sleep(for: .seconds(0.5))
            } else {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.68)) {
                    logoScale = 1
                    logoOpacity = 1
                }
                withAnimation(.easeOut(duration: 0.8)) {
                    glowOpacity = 1
                }
                try? await Task.sleep(for: .seconds(0.35))
                withAnimation(.easeOut(duration: 0.35)) {
                    titleOpacity = 1
                }
                try? await Task.sleep(for: .seconds(0.65))
            }
            onFinished()
        }
        .accessibilityIdentifier("playfit.splash")
    }
}
