import SwiftUI

public enum ToastStyle: Sendable {
    case success, error
}

public struct StatusToast: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let message: String
    let style: ToastStyle

    public init(message: String, style: ToastStyle) {
        self.message = message
        self.style = style
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: style == .success ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(style == .success ? .green : .red)
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        .padding(.horizontal, 16)
        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}

struct ToastOverlayModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var message: String?
    // Bumped by the caller on every showToast() call, including two
    // back-to-back toasts with the *same* text. `.task(id:)` restarts
    // whenever this changes, so a repeated message always gets its own
    // fresh 2.5s window instead of reusing (or being dismissed early by)
    // a stale timer from the previous toast. Keying this off the message
    // string's own Equatable `onChange` doesn't work: SwiftUI skips
    // `onChange` when the new value equals the old one, so an identical
    // repeated message would never restart the timer.
    @Binding var token: Int
    let style: ToastStyle

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let msg = message {
                    StatusToast(message: msg, style: style)
                        .id(token)
                        .padding(.top, 8)
                        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                        .task(id: token) {
                            try? await Task.sleep(for: .seconds(2.5))
                            withAnimation(reduceMotion ? nil : .spring(response: 0.4)) {
                                message = nil
                            }
                        }
                }
            }
            .animation(reduceMotion ? nil : .spring(response: 0.4), value: message)
    }
}

extension View {
    public func statusToast(message: Binding<String?>, token: Binding<Int>, style: ToastStyle) -> some View {
        modifier(ToastOverlayModifier(message: message, token: token, style: style))
    }
}
