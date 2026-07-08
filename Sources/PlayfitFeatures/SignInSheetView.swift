import PlayfitAPI
import PlayfitDesignSystem
import SwiftUI

enum SignInSheetMode {
    case options
    case signIn
    case signUp
}

struct SignInSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.playViewModel) private var viewModel
    @Binding var authEmail: String

    @State private var mode: SignInSheetMode = .options
    @State private var emailInput = ""
    @State private var passwordInput = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.playfitBackground.ignoresSafeArea()
                PlayfitGlowBackground.compact

                ScrollView {
                    VStack(alignment: .center, spacing: PlayfitSpacing.md) {
                        SignInSheetHeaderView(title: titleForView, subtitle: subtitleForView)

                        switch mode {
                        case .options:
                            SignInOptionsView(
                                isLoading: isLoading,
                                onGoogle: signInWithGoogle,
                                onEmail: { withAnimation { mode = .signIn } },
                                onGuest: { dismiss() },
                                onSignUp: { withAnimation { mode = .signUp } }
                            )
                        case .signIn:
                            EmailAuthFormView(
                                mode: .signIn,
                                emailInput: $emailInput,
                                passwordInput: $passwordInput,
                                isLoading: isLoading,
                                onSubmit: signInWithEmail,
                                onResetPassword: resetPassword,
                                onSwitchMode: { withAnimation { mode = .signUp } }
                            )
                        case .signUp:
                            EmailAuthFormView(
                                mode: .signUp,
                                emailInput: $emailInput,
                                passwordInput: $passwordInput,
                                isLoading: isLoading,
                                onSubmit: signUpWithEmail,
                                onResetPassword: nil,
                                onSwitchMode: { withAnimation { mode = .signIn } }
                            )
                        }

                        Spacer()
                    }
                    .padding(PlayfitSpacing.md)
                }
            }
            .navigationTitle(navTitleForView)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if mode != .options {
                        Button {
                            withAnimation { mode = .options }
                        } label: {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .disabled(isLoading)
                    } else {
                        Button("Cancel") { dismiss() }
                            .disabled(isLoading)
                    }
                }
            }
        }
    }

    private var titleForView: String {
        switch mode {
        case .options: "Welcome to Playfit"
        case .signIn: "Sign In"
        case .signUp: "Create Account"
        }
    }

    private var subtitleForView: String {
        switch mode {
        case .options: "Choose how you want to sync your library across devices."
        case .signIn: "Enter your email credentials to access your library."
        case .signUp: "Create an account to backup recommendations in the cloud."
        }
    }

    private var navTitleForView: String {
        switch mode {
        case .options: "Sign In / Sync"
        case .signIn: "Sign In"
        case .signUp: "Create Account"
        }
    }

    private func signInWithGoogle() {
        isLoading = true
        Task {
            do {
                try await viewModel.signInWithGoogle()
                authEmail = viewModel.authSession?.email ?? "Google account"
                isLoading = false
                dismiss()
            } catch AuthError.cancelled {
                isLoading = false
            } catch {
                isLoading = false
                viewModel.showToast("Google sign-in failed: \(error.localizedDescription)", style: .error)
            }
        }
    }

    private func signInWithEmail() {
        guard !emailInput.isEmpty && emailInput.contains("@") else {
            viewModel.showToast("Please enter a valid email address", style: .error)
            return
        }
        guard !passwordInput.isEmpty else {
            viewModel.showToast("Password cannot be empty", style: .error)
            return
        }
        isLoading = true
        Task {
            do {
                try await viewModel.signIn(email: emailInput, password: passwordInput)
                authEmail = emailInput
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                viewModel.showToast("Sign in failed: \(error.localizedDescription)", style: .error)
            }
        }
    }

    private func signUpWithEmail() {
        guard !emailInput.isEmpty && emailInput.contains("@") else {
            viewModel.showToast("Please enter a valid email address", style: .error)
            return
        }
        guard passwordInput.count >= 6 else {
            viewModel.showToast("Password must be at least 6 characters", style: .error)
            return
        }
        isLoading = true
        Task {
            do {
                let hasSession = try await viewModel.signUp(email: emailInput, password: passwordInput)
                isLoading = false
                if hasSession {
                    authEmail = emailInput
                    dismiss()
                } else {
                    viewModel.showToast("Check your email to confirm your account, then sign in.", style: .success)
                    withAnimation { mode = .signIn }
                }
            } catch {
                isLoading = false
                viewModel.showToast("Sign up failed: \(error.localizedDescription)", style: .error)
            }
        }
    }

    private func resetPassword() {
        guard !emailInput.isEmpty else {
            viewModel.showToast("Enter your email address first.", style: .error)
            return
        }
        Task {
            do {
                try await viewModel.resetPassword(email: emailInput)
                viewModel.showToast("If that email is registered, you'll receive a reset link shortly.", style: .success)
            } catch {
                viewModel.showToast("Connection error. Please try again.", style: .error)
            }
        }
    }
}
