import PlayfitDesignSystem
import SwiftUI

struct EmailAuthFormView: View {
    let mode: SignInSheetMode
    @Binding var emailInput: String
    @Binding var passwordInput: String
    let isLoading: Bool
    let onSubmit: () -> Void
    let onResetPassword: (() -> Void)?
    let onSwitchMode: () -> Void

    var body: some View {
        VStack(spacing: PlayfitSpacing.md) {
            PlayfitGlassCard {
                VStack(alignment: .leading, spacing: PlayfitSpacing.sm) {
                    Text("Email Address")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)

                    TextField("name@example.com", text: $emailInput)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        #endif
                        .submitLabel(.next)
                        .onSubmit(onSubmit)
                        .accessibilityLabel("Email address")
                        .padding(12)
                        .frame(minHeight: 44)
                        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                        )

                    Text("Password")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                    SecureField("••••••••", text: $passwordInput)
                        .textFieldStyle(.plain)
                        #if os(iOS)
                        .textContentType(mode == .signUp ? .newPassword : .password)
                        #endif
                        .submitLabel(.go)
                        .onSubmit(onSubmit)
                        .accessibilityLabel("Password")
                        .padding(12)
                        .frame(minHeight: 44)
                        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                        )
                }
                .padding()
            }

            Button(action: onSubmit) {
                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .padding(.trailing, 4)
                    }
                    Text(primaryButtonTitle)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(Color.playfitAccent, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
            .accessibilityLabel(primaryButtonTitle)

            if let onResetPassword {
                Button(action: onResetPassword) {
                    Text("Forgot password?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .underline()
                        .padding(.top, 2)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                .accessibilityLabel("Forgot password?")
            }

            Button(action: onSwitchMode) {
                Text(switchModeTitle)
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .underline()
                    .padding(.top, 4)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(switchModeTitle)
        }
    }

    private var primaryButtonTitle: String {
        switch mode {
        case .options:
            ""
        case .signIn:
            isLoading ? "Authenticating..." : "Sign In & Sync"
        case .signUp:
            isLoading ? "Registering..." : "Create Account"
        }
    }

    private var switchModeTitle: String {
        switch mode {
        case .options:
            ""
        case .signIn:
            "Don't have an account? Create one"
        case .signUp:
            "Already have an account? Sign In"
        }
    }
}
