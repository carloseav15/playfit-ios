import Foundation
import PlayfitAPI
import PlayfitStorage

extension PlayViewModel {
    @MainActor
    public func signIn(email: String, password: String) async throws {
        let client = SupabaseAuthClient()
        let newSession = try await client.signIn(email: email, password: password)
        authSession = newSession
        AuthSessionStore.save(newSession)
        await adoptServerAccountState()
        showToast("Signed in", style: .success)
    }

    /// Returns false when the account was created but needs email confirmation
    /// before a session exists (no session is issued yet in that case).
    @MainActor
    public func signUp(email: String, password: String) async throws -> Bool {
        let client = SupabaseAuthClient()
        guard let newSession = try await client.signUp(email: email, password: password) else {
            return false
        }
        authSession = newSession
        AuthSessionStore.save(newSession)
        await adoptServerAccountState()
        showToast("Account created", style: .success)
        return true
    }

    /// Ensures a guest has a valid Supabase session before any sync call fires,
    /// mirroring the web's `signInAnonymously()` bootstrap. Failures are swallowed
    /// (offline, etc.) so callers can proceed with the existing offline-tolerant paths.
    @MainActor
    func signInAnonymouslyIfNeeded() async {
        guard authSession == nil else { return }
        let client = SupabaseAuthClient()
        guard let newSession = try? await client.signInAnonymously() else { return }
        authSession = newSession
        AuthSessionStore.save(newSession)
    }

    @MainActor
    public func resetPassword(email: String) async throws {
        let client = SupabaseAuthClient()
        try await client.resetPasswordForEmail(email)
    }

    /// Handles `playfit://auth-callback` deep links: Google sign-in adopts the
    /// session immediately, while a password-recovery link holds its session in
    /// `pendingPasswordRecovery` so ResetPasswordView can gate on it without
    /// treating the user as fully signed in until they set a new password.
    @MainActor
    public func handleAuthCallback(url: URL) {
        guard url.scheme == "playfit", url.host == "auth-callback" else { return }
        guard let result = try? SupabaseAuthClient.parseCallbackURL(url) else { return }

        if result.isPasswordRecovery {
            pendingPasswordRecovery = result.session
        } else {
            authSession = result.session
            AuthSessionStore.save(result.session)
            Task { await adoptServerAccountState() }
        }
    }

    @MainActor
    public func updatePassword(_ newPassword: String) async throws {
        guard let recoverySession = pendingPasswordRecovery else {
            throw AuthError.unexpectedResponse
        }
        let client = SupabaseAuthClient()
        try await client.updatePassword(accessToken: recoverySession.accessToken, newPassword: newPassword)
        authSession = recoverySession
        AuthSessionStore.save(recoverySession)
        pendingPasswordRecovery = nil
        await adoptServerAccountState()
        showToast("Password updated", style: .success)
    }

    @MainActor
    public func dismissPasswordRecovery() {
        pendingPasswordRecovery = nil
    }

    @MainActor
    public func signInWithGoogle() async throws {
        let client = SupabaseAuthClient()
        let newSession = try await client.signInWithGoogle()
        authSession = newSession
        AuthSessionStore.save(newSession)
        await adoptServerAccountState()
        showToast("Signed in with Google", style: .success)
    }

    /// Pushes any local profile up (triggering the server-side anonymous-device
    /// migration if this account had none), then pulls the account's real state
    /// back down — including onboarding completion, which a plain push never sets.
    @MainActor
    func adoptServerAccountState() async {
        try? await syncProfileToServer()
        await syncIfOnline()
        guard let apiClient,
              let completedAt = try? await apiClient.fetchOnboardingCompletedAt() else { return }
        onboardingCompleted = true
        onboardingCompletedAt = completedAt
        storage.saveProfile(profile, platformIds: selectedPlatformIds, onboardingCompleted: true)
    }

    @MainActor
    public func signOut() async {
        if let token = authSession?.accessToken {
            let client = SupabaseAuthClient()
            await client.signOut(accessToken: token)
        }
        authSession = nil
        AuthSessionStore.clear()
        showToast("Signed out", style: .success)
    }

    @MainActor
    public func deleteCloudProfile() async throws {
        guard let apiClient else { throw APIError.unexpectedResponse }
        try await apiClient.deleteProfile()
        if let token = authSession?.accessToken {
            await SupabaseAuthClient().signOut(accessToken: token)
        }
        storage.deleteAllLocalData()
        resetAllLocalState()
    }

    /// Deletes the remote taste profile (same DELETE used by `deleteCloudProfile()`)
    /// but keeps the current session active, matching web/Android's "reset stays
    /// signed in" semantics. Local state is only cleared after the remote delete
    /// succeeds, so a failed reset leaves existing data intact.
    @MainActor
    public func resetTasteCloudProfile() async throws {
        guard let apiClient else { throw APIError.unexpectedResponse }
        try await apiClient.deleteProfile()
        storage.deleteAllLocalData()
        resetLocalTasteState()
    }
}
