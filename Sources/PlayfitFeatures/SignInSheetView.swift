import PlayfitAPI
import PlayfitDesignSystem
import SwiftUI

// MARK: - Sign In Sheet View

struct SignInSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.playViewModel) private var viewModel
    @Binding var authEmail: String
    
    @State private var authView: AuthView = .options
    @State private var emailInput = ""
    @State private var passwordInput = ""
    @State private var isLoading = false
    
    private enum AuthView {
        case options
        case signIn
        case signUp
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.playfitBackground.ignoresSafeArea()
                
                PlayfitGlowBackground.compact
                
                ScrollView {
                    VStack(alignment: .center, spacing: PlayfitSpacing.md) {
                        
                        // Logo & Header
                        VStack(spacing: PlayfitSpacing.xs) {
                            Text("PLAYFIT DECISIONS")
                                .font(.caption2.monospaced().weight(.black))
                                .foregroundColor(.playfitAccent)
                                .tracking(2.5)
                                .padding(.top, 16)
                            
                            Text(titleForView)
                                .font(.system(.title, design: .rounded).weight(.black))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            Text(subtitleForView)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .lineSpacing(2)
                        }
                        .padding(.bottom, 8)
                        
                        switch authView {
                        case .options:
                            VStack(spacing: PlayfitSpacing.sm) {
                                // Google Button
                                Button {
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
                                } label: {
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
                                
                                // Email Button
                                Button {
                                    withAnimation {
                                        authView = .signIn
                                    }
                                } label: {
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
                                
                                // Guest Button
                                Button {
                                    dismiss()
                                } label: {
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
                                
                                // Toggle link to sign up
                                Button {
                                    withAnimation {
                                        authView = .signUp
                                    }
                                } label: {
                                    Text("New to Playfit? Create account")
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary)
                                        .underline()
                                        .padding(.top, 12)
                                }
                                .buttonStyle(.plain)
                            }
                            
                        case .signIn:
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
                                            #endif
                                            .padding(12)
                                            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
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
                                            .padding(12)
                                            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                            )
                                    }
                                    .padding()
                                }
                                
                                Button {
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
                                } label: {
                                    HStack {
                                        Spacer()
                                        if isLoading {
                                            ProgressView()
                                                .tint(.white)
                                                .padding(.trailing, 4)
                                        }
                                        Text(isLoading ? "Authenticating..." : "Sign In & Sync")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.vertical, 14)
                                    .background(Color.playfitAccent, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .disabled(isLoading)

                                Button {
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
                                } label: {
                                    Text("Forgot password?")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .underline()
                                        .padding(.top, 2)
                                }
                                .buttonStyle(.plain)
                                .disabled(isLoading)

                                Button {
                                    withAnimation {
                                        authView = .signUp
                                    }
                                } label: {
                                    Text("Don't have an account? Create one")
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary)
                                        .underline()
                                        .padding(.top, 4)
                                }
                                .buttonStyle(.plain)
                            }

                        case .signUp:
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
                                            #endif
                                            .padding(12)
                                            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
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
                                            .padding(12)
                                            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                            )
                                    }
                                    .padding()
                                }
                                
                                Button {
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
                                                withAnimation { authView = .signIn }
                                            }
                                        } catch {
                                            isLoading = false
                                            viewModel.showToast("Sign up failed: \(error.localizedDescription)", style: .error)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Spacer()
                                        if isLoading {
                                            ProgressView()
                                                .tint(.white)
                                                .padding(.trailing, 4)
                                        }
                                        Text(isLoading ? "Registering..." : "Create Account")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.vertical, 14)
                                    .background(Color.playfitAccent, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .disabled(isLoading)
                                
                                Button {
                                    withAnimation {
                                        authView = .signIn
                                    }
                                } label: {
                                    Text("Already have an account? Sign In")
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary)
                                        .underline()
                                        .padding(.top, 4)
                                }
                                .buttonStyle(.plain)
                            }
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
                    if authView != .options {
                        Button {
                            withAnimation {
                                authView = .options
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .disabled(isLoading)
                    } else {
                        Button("Cancel") {
                            dismiss()
                        }
                        .disabled(isLoading)
                    }
                }
            }
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
    
    private var titleForView: String {
        switch authView {
        case .options: "Welcome to Playfit"
        case .signIn: "Sign In"
        case .signUp: "Create Account"
        }
    }
    
    private var subtitleForView: String {
        switch authView {
        case .options: "Choose how you want to sync your library across devices."
        case .signIn: "Enter your email credentials to access your library."
        case .signUp: "Create an account to backup recommendations in the cloud."
        }
    }
    
    private var navTitleForView: String {
        switch authView {
        case .options: "Sign In / Sync"
        case .signIn: "Sign In"
        case .signUp: "Create Account"
        }
    }
    
}
