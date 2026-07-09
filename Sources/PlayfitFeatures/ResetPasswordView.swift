import PlayfitDesignSystem
import SwiftUI

struct ResetPasswordView: View {
    @Environment(\.playViewModel) private var viewModel
    @State private var passwordInput = ""
    @State private var confirmPasswordInput = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.playfitBackground.ignoresSafeArea()
                PlayfitGlowBackground.compact

                ScrollView {
                    VStack(alignment: .center, spacing: PlayfitSpacing.md) {
                        SignInSheetHeaderView(
                            title: "Reset Password",
                            subtitle: "Choose a new password for your account."
                        )

                        PlayfitGlassCard {
                            VStack(alignment: .leading, spacing: PlayfitSpacing.sm) {
                                Text("New Password")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)

                                SecureField("At least 6 characters", text: $passwordInput)
                                    .textFieldStyle(.plain)
                                    #if os(iOS)
                                    .textContentType(.newPassword)
                                    #endif
                                    .submitLabel(.next)
                                    .accessibilityLabel("New password")
                                    .padding(12)
                                    .frame(minHeight: 44)
                                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                    )

                                Text("Confirm Password")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)

                                SecureField("Re-enter your new password", text: $confirmPasswordInput)
                                    .textFieldStyle(.plain)
                                    #if os(iOS)
                                    .textContentType(.newPassword)
                                    #endif
                                    .submitLabel(.go)
                                    .onSubmit(updatePassword)
                                    .accessibilityLabel("Confirm new password")
                                    .padding(12)
                                    .frame(minHeight: 44)
                                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                    )
                            }
                            .padding()
                        }

                        Button(action: updatePassword) {
                            HStack {
                                Spacer()
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .padding(.trailing, 4)
                                }
                                Text(isLoading ? "Updating…" : "Update Password")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 14)
                            .background(Color.playfitAccent, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoading)
                        .accessibilityLabel(isLoading ? "Updating password" : "Update Password")

                        Spacer()
                    }
                    .padding(PlayfitSpacing.md)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .navigationTitle("Reset Password")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.dismissPasswordRecovery() }
                        .disabled(isLoading)
                        .accessibilityLabel("Cancel password reset")
                }
            }
        }
    }

    private func updatePassword() {
        guard passwordInput.count >= 6 else {
            viewModel.showToast("Password must be at least 6 characters", style: .error)
            return
        }
        guard passwordInput == confirmPasswordInput else {
            viewModel.showToast("Passwords don't match", style: .error)
            return
        }
        isLoading = true
        Task {
            do {
                try await viewModel.updatePassword(passwordInput)
                isLoading = false
            } catch {
                isLoading = false
                viewModel.showToast("Could not update password. Please try again.", style: .error)
            }
        }
    }
}
