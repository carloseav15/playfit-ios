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
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isLoading)

            Button(action: onEmail) {
                HStack(spacing: PlayfitSpacing.sm) {
                    Spacer()
                    Image(systemName: "mail.fill")
                        .foregroundColor(.playfitAccent)
                    Text("Continue with Email")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isLoading)

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

            Button(action: onSignUp) {
                Text("New to Playfit? Create account")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .underline()
                    .padding(.top, 12)
            }
            .buttonStyle(.plain)
        }
    }

    private var googleLogo: some View {
        HStack(spacing: 0) {
            Text("G")
                .font(.system(size: 16, weight: .black, design: .rounded))
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
    }
}
