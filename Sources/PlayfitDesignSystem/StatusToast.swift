import SwiftUI

public enum ToastStyle: Sendable {
    case success, error
}

public struct StatusToast: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let message: String
    let style: ToastStyle
    let actionTitle: String?
    let action: (() -> Void)?

    public init(message: String, style: ToastStyle, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.message = message
        self.style = style
        self.actionTitle = actionTitle
        self.action = action
    }

    private var hasAction: Bool { actionTitle != nil && action != nil }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: style == .success ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(style == .success ? .green : .red)
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
            if let actionTitle, let action {
                Spacer(minLength: 8)
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        .padding(.horizontal, 16)
        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
        // A plain toast reads as one static-text block. Once there's a
        // real Undo button, .combine would swallow it into that same
        // block and VoiceOver users couldn't reach or activate it — so
        // this case switches to .contain to keep the button a separate,
        // focusable element instead.
        .accessibilityElement(children: hasAction ? .contain : .combine)
        .accessibilityAddTraits(hasAction ? [] : .isStaticText)
    }
}

struct ToastOverlayModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var message: String?
    // Bumped by the caller on every showToast() call, including two
    // back-to-back toasts with the *same* text. `.task(id:)` restarts
    // whenever this changes, so a repeated message always gets its own
    // fresh window instead of reusing (or being dismissed early by)
    // a stale timer from the previous toast. Keying this off the message
    // string's own Equatable `onChange` doesn't work: SwiftUI skips
    // `onChange` when the new value equals the old one, so an identical
    // repeated message would never restart the timer.
    @Binding var token: Int
    let style: ToastStyle
    @Binding var actionTitle: String?
    @Binding var action: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let msg = message {
                    StatusToast(message: msg, style: style, actionTitle: actionTitle, action: action)
                        .id(token)
                        .padding(.top, 8)
                        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                        .task(id: token) {
                            // Toasts with an Undo action get a longer window
                            // so there's real time to tap it before it dismisses.
                            try? await Task.sleep(for: .seconds(action != nil ? 5 : 2.5))
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
    public func statusToast(
        message: Binding<String?>,
        token: Binding<Int>,
        style: ToastStyle,
        actionTitle: Binding<String?>,
        action: Binding<(() -> Void)?>
    ) -> some View {
        modifier(ToastOverlayModifier(message: message, token: token, style: style, actionTitle: actionTitle, action: action))
    }
}
