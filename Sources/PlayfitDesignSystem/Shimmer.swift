import SwiftUI

/// A subtle animated highlight sweep for skeleton/placeholder content, honoring
/// Reduce Motion by staying static instead of animating.
private struct ShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -0.3

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    GeometryReader { geometry in
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.35), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 0.6)
                        .offset(x: phase * geometry.size.width)
                        .blendMode(.plusLighter)
                    }
                }
            }
            .clipped()
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                    phase = 1.3
                }
            }
    }
}

extension View {
    /// Adds a moving highlight sweep, typically layered on top of
    /// `.redacted(reason: .placeholder)` skeleton content.
    public func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}
