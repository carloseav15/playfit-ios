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

        if let localProfile = storage.loadProfile() {
            profile = localProfile
        }

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

        authSession = AuthSessionStore.load()
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
        guard let apiClient else {
            syncState = .offline
            return
        }
        isLoading = true
        syncState = .syncing
        error = nil
        do {
            await drainPendingActions()

            let playNextResult: PlayNextModel
            do {
                playNextResult = try await apiClient.fetchPlayNext()
            } catch APIError.server(200, _) {
                try await syncProfileToServer()
                playNextResult = try await apiClient.fetchPlayNext()
            }

            async let profileData = apiClient.fetchProfile()
            async let gameStatesData = apiClient.fetchGameStates()
            async let picksData = apiClient.fetchPicks()

            let (profileResult, gameStatesResult, picksResult) = try await (
                profileData,
                gameStatesData,
                picksData
            )

            if let platformsResult = try? await apiClient.fetchPlatforms(), !platformsResult.isEmpty {
                self.platforms = platformsResult
            }

            self.pool = ([playNextResult.primary].compactMap { $0 } + playNextResult.alternatives)
            self.gameStates = overlayStillPending(on: gameStatesResult)
            self.pickRecommendations = picksResult
            if let profile = profileResult {
                self.profile = profile
            }
            self.pickIds = activePickIds(in: self.gameStates)
            self.stablePrimaryId = playNextResult.primary?.game.id
            self.excludedIds = []

            storage.cacheRecommendations(uniqueRecommendations(self.pool + self.pickRecommendations))
            storage.saveProfile(self.profile, platformIds: self.selectedPlatformIds, onboardingCompleted: self.onboardingCompleted)
            for (gameId, state) in self.gameStates {
                storage.saveGameState(gameId: gameId, state: state)
            }
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
        try await apiClient.saveProfile(
            profile: profile,
            gameStates: gameStates,
            onboarding: buildOnboardingPayload()
        )
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
            async let playNextData = apiClient.fetchPlayNext()
            async let picksData = apiClient.fetchPicks()
            let (playNext, picksResult) = try await (playNextData, picksData)
            let existingIds = Set(pool.map(\.game.id))
            let fresh = ([playNext.primary].compactMap { $0 } + playNext.alternatives)
                .filter { !excludedIds.contains($0.game.id) || !existingIds.contains($0.game.id) }
            self.pool = fresh
            self.pickRecommendations = picksResult
            self.pickIds = activePickIds(in: gameStates)
            self.stablePrimaryId = playNext.primary?.game.id

            storage.cacheRecommendations(uniqueRecommendations(fresh + picksResult))
            self.lastSyncedAt = Date()
            self.syncState = .synced
        } catch {
            self.error = "Unable to sync. Changes will be saved locally."
            self.syncState = .failed
        }
        isLoading = false
    }

    func saveGameStateOrQueue(gameId: String, state: UserGameState) {
        guard let apiClient else {
            queueSaveGameState(gameId: gameId, state: state)
            return
        }
        Task {
            do {
                try await apiClient.saveGameState(gameId: gameId, state: state)
                storage.removePendingAction(gameId: gameId, actionType: PendingActionType.saveGameState.rawValue)
            } catch {
                queueSaveGameState(gameId: gameId, state: state)
            }
        }
    }

    func deleteGameStateOrQueue(gameId: String) {
        guard let apiClient else {
            storage.enqueuePendingAction(gameId: gameId, actionType: PendingActionType.deleteGameState.rawValue, payload: Data())
            return
        }
        Task {
            do {
                try await apiClient.deleteGameState(gameId: gameId)
                storage.removePendingAction(gameId: gameId, actionType: PendingActionType.deleteGameState.rawValue)
            } catch {
                storage.enqueuePendingAction(gameId: gameId, actionType: PendingActionType.deleteGameState.rawValue, payload: Data())
            }
        }
    }

    private func queueSaveGameState(gameId: String, state: UserGameState) {
        guard let payload = try? JSONEncoder().encode(state) else { return }
        storage.enqueuePendingAction(gameId: gameId, actionType: PendingActionType.saveGameState.rawValue, payload: payload)
    }

    /// Attempts to push every queued action to the server. Items that still fail
    /// (offline, server error) are left in the queue for the next sync attempt.
    private func drainPendingActions() async {
        guard let apiClient else { return }
        let pending = storage.loadPendingActions()
        for action in pending {
            guard let type = PendingActionType(rawValue: action.actionType) else { continue }
            do {
                switch type {
                case .saveGameState:
                    let state = try JSONDecoder().decode(UserGameState.self, from: action.payload)
                    try await apiClient.saveGameState(gameId: action.gameId, state: state)
                case .deleteGameState:
                    try await apiClient.deleteGameState(gameId: action.gameId)
                }
                storage.removePendingAction(id: action.id)
            } catch {
                // Leave queued; will be retried on the next syncIfOnline().
            }
        }
    }

    /// Re-applies any action still stuck in the queue on top of a freshly fetched
    /// server snapshot, so a pending local change is never visually undone.
    private func overlayStillPending(on serverGameStates: [String: UserGameState]) -> [String: UserGameState] {
        var merged = serverGameStates
        for action in storage.loadPendingActions() {
            guard let type = PendingActionType(rawValue: action.actionType) else { continue }
            switch type {
            case .saveGameState:
                if let state = try? JSONDecoder().decode(UserGameState.self, from: action.payload) {
                    merged[action.gameId] = state
                }
            case .deleteGameState:
                merged.removeValue(forKey: action.gameId)
            }
        }
        return merged
    }

    @MainActor
    public func hydrateTasteGames() async {
        for rec in pool + pickRecommendations {
            gamesCache[rec.game.id] = rec.game
        }

        let statesIds = gameStates.keys
        let signalIds = profile.signals.map { $0.id }
        let allNeededIds = Array(
            Set(statesIds)
                .union(signalIds)
                .union(onboardingLikedGameIds)
                .union(onboardingDislikedGameIds)
        )

        let missingIds = allNeededIds.filter { gamesCache[$0] == nil }
        guard !missingIds.isEmpty else {
            rebuildProfileFromCurrentSignals()
            return
        }
        guard let apiClient else {
            rebuildProfileFromCurrentSignals()
            return
        }

        isLoading = true
        do {
            let fetchedGames = try await apiClient.fetchGamesBatch(gameIds: missingIds)
            for game in fetchedGames {
                gamesCache[game.id] = game
            }
            rebuildProfileFromCurrentSignals()
        } catch {
            self.error = "Unable to sync. Changes will be saved locally."
        }
        isLoading = false
    }
}
