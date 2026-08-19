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
        recordRecommendationObservation("recommendation_saved", entry: entry)
        storage.cacheRecommendations(uniqueRecommendations(pool + pickRecommendations))
        showToast("Saved to Picks")
    }

    public func notForMe(_ entry: RankedRecommendation) {
        applyFeedbackWithUndo(entry, feedback: .notForMe)
    }

    public func alreadyPlayed(_ entry: RankedRecommendation, feedback: AlreadyPlayedFeedback) {
        applyFeedbackWithUndo(entry, feedback: feedback)
    }

    /// Shared by `notForMe`/`alreadyPlayed`: both discard the current
    /// recommendation and record permanent feedback that reshapes future
    /// picks, so both get the same snapshot-and-offer-Undo treatment
    /// (mirrors `applyDecisionFeedback` on web, which is likewise generic
    /// over every `DecisionFeedback` case rather than one-off per action).
    private func applyFeedbackWithUndo(_ entry: RankedRecommendation, feedback: DecisionFeedback) {
        if let canonical = canonicalAction(for: feedback) {
            beginCanonicalDecision(
                entry,
                actionType: canonical.actionType,
                played: canonical.played
            )
            return
        }

        pendingUndo = .legacy(
            entry: entry,
            previousState: gameStates[entry.game.id],
            wasPicked: pickIds.contains(entry.game.id)
        )
        advancePast(entry.game.id)
        gamesCache[entry.game.id] = entry.game
        pickIds.remove(entry.game.id)
        pickRecommendations.removeAll { $0.game.id == entry.game.id }
        applyDecisionFeedback(gameStates: &gameStates, gameId: entry.game.id, feedback: feedback)
        persistGameState(gameId: entry.game.id)
        rebuildProfileFromCurrentSignals()
        showToast(decisionFeedbackMessage(for: feedback), actionTitle: "Undo") { [weak self] in
            self?.undoLastDecision()
        }
    }

    public func undoLastDecision() {
        guard let undo = pendingUndo else { return }
        switch undo {
        case .canonical(let targetOperationId, let gameId):
            beginCanonicalUndo(targetOperationId: targetOperationId, gameId: gameId)
        case .legacy(let entry, let previousState, let wasPicked):
            pendingUndo = nil
            undoLegacyDecision(
                entry: entry,
                previousState: previousState,
                wasPicked: wasPicked
            )
        }
    }

    private func undoLegacyDecision(
        entry: RankedRecommendation,
        previousState: UserGameState?,
        wasPicked: Bool
    ) {
        let gameId = entry.game.id

        if let previousState {
            gameStates[gameId] = previousState
            persistGameState(gameId: gameId)
        } else {
            gameStates.removeValue(forKey: gameId)
            storage.deleteGameState(gameId: gameId)
            deleteGameStateOrQueue(gameId: gameId)
        }

        if wasPicked {
            pickIds.insert(gameId)
            var restoredEntry = entry
            restoredEntry.inPlayfitPicks = true
            pickRecommendations.removeAll { $0.game.id == gameId }
            pickRecommendations.insert(restoredEntry, at: 0)
            storage.cacheRecommendations(uniqueRecommendations(pool + pickRecommendations))
        }

        excludedIds.remove(gameId)
        stablePrimaryId = gameId
        rebuildProfileFromCurrentSignals()
        showToast("Undone.")
    }

    private func canonicalAction(
        for feedback: DecisionFeedback
    ) -> (actionType: CanonicalDecisionActionType, played: Bool)? {
        switch feedback {
        case .play:
            (.started, false)
        case .notForMe:
            (.notForMe, false)
        case .loved:
            (.loved, false)
        case .liked:
            (.liked, false)
        case .playedLoved:
            (.loved, true)
        case .playedLiked:
            (.liked, true)
        case .playedMixed:
            (.mixed, true)
        case .playedDropped:
            (.dropped, true)
        default:
            nil
        }
    }

    public func skip(_ entry: RankedRecommendation) {
        recordRecommendationObservation("recommendation_skipped", entry: entry)
        advancePast(entry.game.id)
        showToast("Skipped")
    }

    /// Restores skipped games immediately (guaranteed non-empty), then asks
    /// the server for fresh candidates too — otherwise this button just
    /// re-serves the exact same dead-end pool with no network activity, and
    /// swiping through it again loops back to the identical empty state
    /// forever.
    @MainActor
    public func showSkippedAgain() async {
        excludedIds = []
        showToast("Skipped games shown again")
        await refresh()
    }

    public func clearError() {
        error = nil
        if syncState == .failed { syncState = .idle }
    }

    /// Clears taste/onboarding/recommendation state without touching the auth
    /// session, so a taste reset can keep the user signed in.
    @MainActor
    public func resetLocalTasteState() {
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
        stateVersion = "0"
        rankingMetadata = RankingMetadata(profileStateVersion: "0")
        canonicalStatusMessage = nil
        hasAuthoritativeSnapshot = false
        pendingUndo = nil
        error = nil
        syncState = apiClient == nil ? .offline : .idle
        lastSyncedAt = nil
    }

    @MainActor
    public func resetAllLocalState() {
        resetLocalTasteState()
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

    public func showToast(
        _ message: String,
        style: ToastStyle = .success,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        toastMessage = message
        toastStyle = style
        toastActionTitle = actionTitle
        toastAction = action
        toastToken += 1
    }

    /// Mirrors `productDecisionFeedbackMessages` on web
    /// (product/packages/core/src/domain/feedback.ts) so the same action
    /// reads the same way on both platforms.
    private func decisionFeedbackMessage(for feedback: DecisionFeedback) -> String {
        switch feedback {
        case .play: "Started. This updates Play Next, not your taste."
        case .later: "Saved for later. Playfit will look past it for now."
        case .loved: "Marked as loved."
        case .liked: "Marked as liked."
        case .mixed: "Marked as mixed."
        case .notForMe: "Noted. Playfit will find a better fit."
        case .playedLoved: "Already played and loved. Playfit will learn from it."
        case .playedLiked: "Already played and liked."
        case .playedMixed: "Marked as mixed. This records the game without changing your taste profile."
        case .playedDropped: "Marked as dropped. Playfit will steer away."
        }
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
