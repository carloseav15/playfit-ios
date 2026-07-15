import PlayfitDesignSystem
import SwiftUI

struct SignInOptionsView: View {
    let isLoading: Bool
    let onGoogle: () -> Void
    let onEmail: () -> Void
    let onGuest: () -> Void
    let onSignUp: () -> Void

    var body: some View {
        VStack(spacing: PlayfitSpacing.sm) {
            Button(action: onGoogle) {
                HStack(spacing: PlayfitSpacing.sm) {
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        googleLogo
                        Text("Continue with Google")
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                            .accessibilityIgnoresInvertColors(true)
                    }
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
            .accessibilityLabel("Continue with Google")

            Button(action: onEmail) {
                HStack(spacing: PlayfitSpacing.sm) {
                    Spacer()
                    Image(systemName: "mail.fill")
                        .foregroundColor(.playfitAccent)
                    Text("Continue with Email")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                        .accessibilityIgnoresInvertColors(true)
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
            .accessibilityLabel("Continue with Email")

            Button(action: onGuest) {
                HStack {
                    Spacer()
                    Text("Continue as Guest")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
            .accessibilityLabel("Continue as Guest")

            Button(action: onSignUp) {
                Text("New to Playfit? Create account")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .underline()
                    .padding(.top, 12)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("New to Playfit? Create account")
        }
    }

    private var googleLogo: some View {
        HStack(spacing: 0) {
            Text("G")
                .font(.body.weight(.black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .yellow, .green, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: 22, height: 22)
        .background(.white, in: Circle())
        .accessibilityHidden(true)
    }
}
