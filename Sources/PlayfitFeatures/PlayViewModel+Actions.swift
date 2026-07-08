import PlayfitAPI
import PlayfitDesignSystem
import PlayfitLogic
import PlayfitModels
import PlayfitStorage

extension PlayViewModel {
    public func addPick(_ entry: RankedRecommendation) {
        guard pickIds.count < 100 else {
            showToast("Picks is limited to 100 games", style: .error)
            return
        }
        let state = gameStates[entry.game.id]
        guard state?.excluded != true,
              state?.status.map({ !isTerminal($0) }) ?? true else {
            showToast("Finished or excluded games cannot be added to Picks", style: .error)
            return
        }
        advancePast(entry.game.id)
        pickIds.insert(entry.game.id)
        gamesCache[entry.game.id] = entry.game
        setPlayfitPick(gameStates: &gameStates, gameId: entry.game.id, picked: true)
        var savedEntry = entry
        savedEntry.inPlayfitPicks = true
        pickRecommendations.removeAll { $0.game.id == entry.game.id }
        pickRecommendations.insert(savedEntry, at: 0)
        persistGameState(gameId: entry.game.id)
        storage.cacheRecommendations(uniqueRecommendations(pool + pickRecommendations))
        showToast("Saved to Picks")
    }

    public func notForMe(_ entry: RankedRecommendation) {
        advancePast(entry.game.id)
        gamesCache[entry.game.id] = entry.game
        pickIds.remove(entry.game.id)
        pickRecommendations.removeAll { $0.game.id == entry.game.id }
        applyDecisionFeedback(gameStates: &gameStates, gameId: entry.game.id, feedback: .notForMe)
        persistGameState(gameId: entry.game.id)
        rebuildProfileFromCurrentSignals()
        showToast("Skipped")
    }

    public func alreadyPlayed(_ entry: RankedRecommendation, feedback: AlreadyPlayedFeedback) {
        advancePast(entry.game.id)
        gamesCache[entry.game.id] = entry.game
        pickIds.remove(entry.game.id)
        pickRecommendations.removeAll { $0.game.id == entry.game.id }
        applyDecisionFeedback(gameStates: &gameStates, gameId: entry.game.id, feedback: feedback)
        persistGameState(gameId: entry.game.id)
        rebuildProfileFromCurrentSignals()
        showToast("Marked as played")
    }

    public func skip(_ entry: RankedRecommendation) {
        advancePast(entry.game.id)
        showToast("Skipped")
    }

    public func clearSkipped() {
        excludedIds = []
        showToast("Skipped games shown again")
    }

    public func clearError() {
        error = nil
        if syncState == .failed { syncState = .idle }
    }

    @MainActor
    public func resetAllLocalState() {
        pool = []
        pickRecommendations = []
        gameStates = [:]
        pickIds = []
        excludedIds = []
        stablePrimaryId = nil
        selectedPlatformIds = []
        onboardingStarted = false
        onboardingCompleted = false
        onboardingLikedGameIds = []
        onboardingDislikedGameIds = []
        onboardingCompletedAt = nil
        profile = UserProfile()
        error = nil
        syncState = apiClient == nil ? .offline : .idle
        lastSyncedAt = nil
        authSession = nil
        AuthSessionStore.clear()
    }

    public func removePick(_ gameId: String) {
        pickIds.remove(gameId)
        pickRecommendations.removeAll { $0.game.id == gameId }
        setPlayfitPick(gameStates: &gameStates, gameId: gameId, picked: false)
        persistGameState(gameId: gameId)
        storage.cacheRecommendations(uniqueRecommendations(pool + pickRecommendations))
        showToast("Removed from Picks")
    }

    public func deleteSignal(_ gameId: String, source: String) {
        if source == "onboarding_liked" {
            onboardingLikedGameIds.removeAll { $0 == gameId }
        } else if source == "onboarding_disliked" {
            onboardingDislikedGameIds.removeAll { $0 == gameId }
        } else if var state = gameStates[gameId] {
            state.rating = nil
            state.excluded = false
            if let status = state.status, isTerminal(status) {
                state.status = nil
            }
            if state.inPlayfitPicks || state.inBacklog || state.inWishlist {
                gameStates[gameId] = state
                persistGameState(gameId: gameId)
            } else {
                gameStates.removeValue(forKey: gameId)
                storage.deleteGameState(gameId: gameId)
                deleteGameStateOrQueue(gameId: gameId)
            }
        }
        if source != "rating",
           let state = gameStates[gameId],
           state.source == "onboarding",
           state.rating == nil,
           state.status == nil,
           !state.inPlayfitPicks,
           !state.inBacklog,
           !state.inWishlist,
           !state.excluded {
            gameStates.removeValue(forKey: gameId)
            storage.deleteGameState(gameId: gameId)
            deleteGameStateOrQueue(gameId: gameId)
        }
        storage.saveOnboardingMetadata(
            likedIds: onboardingLikedGameIds,
            dislikedIds: onboardingDislikedGameIds,
            completedAt: onboardingCompletedAt
        )
        rebuildProfileFromCurrentSignals()
        showToast("Signal deleted")
    }

    public func updateSignal(gameId: String, feedback: String) {
        guard let decision = DecisionFeedback(rawValue: feedback) else { return }
        applyDecisionFeedback(gameStates: &gameStates, gameId: gameId, feedback: decision)
        if gameStates[gameId]?.inPlayfitPicks != true {
            pickIds.remove(gameId)
            pickRecommendations.removeAll { $0.game.id == gameId }
        }
        persistGameState(gameId: gameId)
        rebuildProfileFromCurrentSignals()
        showToast("Signal updated")
    }

    public func showToast(_ message: String, style: ToastStyle = .success) {
        toastMessage = message
        toastStyle = style
    }

    func advancePast(_ gameId: String) {
        excludedIds.insert(gameId)
        if stablePrimaryId == gameId {
            stablePrimaryId = visiblePool.first(where: { $0.game.id != gameId })?.game.id
        }
    }

    func persistGameState(gameId: String) {
        guard let state = gameStates[gameId] else { return }
        storage.saveGameState(gameId: gameId, state: state)
        saveGameStateOrQueue(gameId: gameId, state: state)
    }
}
