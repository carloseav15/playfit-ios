import Foundation
import PlayfitAPI
import PlayfitLogic
import PlayfitModels
import PlayfitStorage

extension PlayViewModel {
    @MainActor
    public func loadLocal() {
        let status = storage.loadOnboardingStatus()
        onboardingCompleted = status.completed
        selectedPlatformIds = status.platformIds
        platforms = Self.fallbackPlatforms

        authSession = AuthSessionStore.load()

        if let authoritative = storage.loadAuthoritativeSnapshot() {
            applyAuthoritativeSnapshot(authoritative)
            return
        }

        if let localProfile = storage.loadProfile() { profile = localProfile }

        let meta = storage.loadOnboardingMetadata()
        self.onboardingLikedGameIds = meta.likedIds
        self.onboardingDislikedGameIds = meta.dislikedIds
        self.onboardingCompletedAt = meta.completedAt

        // Auto-heal missing onboarding metadata if onboarding was already completed
        if onboardingCompleted && onboardingCompletedAt == nil {
            let now = ISO8601DateFormatter().string(from: Date())
            self.onboardingCompletedAt = now
            let states = storage.loadGameStates()
            let likedFromStates = states.filter { $0.value.rating == 5.0 }.map { $0.key }
            let avoidedFromStates = states.filter { $0.value.excluded }.map { $0.key }
            self.onboardingLikedGameIds = likedFromStates.isEmpty ? ["celeste"] : likedFromStates
            self.onboardingDislikedGameIds = avoidedFromStates
            storage.saveOnboardingMetadata(likedIds: onboardingLikedGameIds, dislikedIds: onboardingDislikedGameIds, completedAt: now)
        }

        gameStates = storage.loadGameStates()
        let cached = storage.loadCachedRecommendations()
        if !cached.isEmpty {
            pickIds = activePickIds(in: gameStates)
            pickRecommendations = cached.filter { pickIds.contains($0.game.id) }
            pool = cached.filter { !pickIds.contains($0.game.id) }
            stablePrimaryId = pool.first?.game.id
        } else if onboardingCompleted {
            isLoading = true
            error = "No cached recommendations available. Connect to sync."
        }
    }

    @MainActor
    public func syncIfOnline() async {
        await drainTelemetryEvents()
        guard let apiClient else {
            syncState = .offline
            return
        }
        isLoading = true
        syncState = .syncing
        error = nil
        do {
            let snapshot: AuthoritativeSnapshot
            do {
                snapshot = try await apiClient.fetchAuthoritativeSnapshot()
            } catch APIError.server(200, _) {
                try await syncProfileToServer()
                snapshot = try await apiClient.fetchAuthoritativeSnapshot()
            }
            applyAuthoritativeSnapshot(snapshot)

            await drainCanonicalDecisions()
            if !storage.loadCanonicalDecisions().isEmpty {
                isLoading = false
                return
            }
            await drainPendingActions()

            async let picksData = apiClient.fetchPicks()
            let picksResult = try await picksData

            if let platformsResult = try? await apiClient.fetchPlatforms(), !platformsResult.isEmpty {
                self.platforms = platformsResult
            }

            self.pickRecommendations = picksResult
            self.pickIds = activePickIds(in: self.gameStates)

            storage.cacheRecommendations(uniqueRecommendations(self.pool + self.pickRecommendations))
            self.lastSyncedAt = Date()
            self.syncState = .synced
        } catch {
            self.error = "Unable to sync. Changes will be saved locally."
            self.syncState = .failed
        }
        isLoading = false
    }

    public func buildOnboardingPayload() -> OnboardingPayload {
        OnboardingPayload(
            step: onboardingCompleted ? "dislikes" : "platforms",
            platforms: Array(selectedPlatformIds),
            likedGameIds: onboardingLikedGameIds,
            dislikedGameIds: onboardingDislikedGameIds,
            onboardingCompletedAt: onboardingCompletedAt
        )
    }

    @MainActor
    public func syncProfileToServer() async throws {
        guard let apiClient else { return }
        let persistedVersion = try await apiClient.saveProfile(
            profile: profile,
            gameStates: gameStates,
            onboarding: buildOnboardingPayload(),
            stateVersion: stateVersion
        )
        stateVersion = persistedVersion
        hasAuthoritativeSnapshot = false
    }

    @MainActor
    public func load() async {
        loadLocal()
        await signInAnonymouslyIfNeeded()
        if let apiClient {
            if let fetched = try? await apiClient.fetchPlatforms(), !fetched.isEmpty {
                self.platforms = fetched
            }
        }
        if onboardingCompleted {
            await syncIfOnline()
        }
    }

    public func refresh() async {
        guard let apiClient else {
            syncState = .offline
            return
        }
        isLoading = true
        syncState = .syncing
        error = nil
        do {
            async let snapshotData = apiClient.fetchAuthoritativeSnapshot()
            async let picksData = apiClient.fetchPicks()
            let (snapshot, picksResult) = try await (snapshotData, picksData)
            applyAuthoritativeSnapshot(snapshot)
            self.pickRecommendations = picksResult
            self.pickIds = activePickIds(in: gameStates)

            storage.cacheRecommendations(uniqueRecommendations(pool + picksResult))
            self.lastSyncedAt = Date()
            self.syncState = .synced
        } catch {
            self.error = "Unable to sync. Changes will be saved locally."
            self.syncState = .failed
        }
        isLoading = false
    }

}
