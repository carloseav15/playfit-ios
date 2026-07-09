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
}
