import Foundation
import PlayfitAPI
import PlayfitModels

extension PlayViewModel {
    func beginCanonicalDecision(
        _ entry: RankedRecommendation,
        actionType: CanonicalDecisionActionType,
        played: Bool
    ) {
        let command = CanonicalDecisionCommand(
            expectedStateVersion: stateVersion,
            actionType: actionType,
            gameId: entry.game.id,
            played: played ? true : nil
        )
        pendingUndo = nil
        gamesCache[entry.game.id] = entry.game
        storage.enqueueCanonicalDecision(command)
        retireCanonicalRecommendationPool(gameId: entry.game.id)

        guard apiClient != nil else {
            isLoading = false
            syncState = .offline
            canonicalStatusMessage = "Saved offline — recommendations will update after sync."
            showToast("Saved offline — recommendations will update after sync.")
            return
        }

        isLoading = true
        canonicalStatusMessage = "Updating your next pick…"
        Task { await drainCanonicalDecisions() }
    }

    func beginCanonicalUndo(targetOperationId: String, gameId: String) {
        let command = CanonicalDecisionCommand(
            expectedStateVersion: stateVersion,
            actionType: .undoDecision,
            targetOperationId: targetOperationId
        )
        storage.enqueueCanonicalDecision(command)
        retireCanonicalRecommendationPool(gameId: gameId)

        guard apiClient != nil else {
            isLoading = false
            syncState = .offline
            canonicalStatusMessage = "Saved offline — recommendations will update after sync."
            showToast("Saved offline — recommendations will update after sync.")
            return
        }

        isLoading = true
        canonicalStatusMessage = "Updating your next pick…"
        Task { await drainCanonicalDecisions() }
    }

    private func retireCanonicalRecommendationPool(gameId: String) {
        excludedIds.insert(gameId)
        pool = []
        stablePrimaryId = nil
    }

    @MainActor
    func drainCanonicalDecisions() async {
        guard !canonicalDrainInProgress, let apiClient else {
            if apiClient == nil {
                syncState = .offline
                canonicalStatusMessage = "Saved offline — recommendations will update after sync."
            }
            return
        }

        canonicalDrainInProgress = true
        isLoading = true
        canonicalStatusMessage = "Updating your next pick…"
        defer {
            canonicalDrainInProgress = false
            isLoading = false
        }

        var lastApplied: CanonicalDecisionCommand?
        for storedCommand in storage.loadCanonicalDecisions() {
            var command = storedCommand
            if command.expectedStateVersion != stateVersion {
                guard command.actionType != .undoDecision else {
                    canonicalStatusMessage = "Undo needs the latest authoritative state."
                    syncState = .failed
                    return
                }
                command.expectedStateVersion = stateVersion
                storage.updateCanonicalDecisionExpectedVersion(
                    operationId: command.operationId,
                    stateVersion: stateVersion
                )
            }

            do {
                let response = try await apiClient.submitCanonicalDecision(command)
                let applied = try applyCanonicalResponse(response, for: command)
                storage.removeCanonicalDecision(operationId: command.operationId)
                if applied { lastApplied = command }
            } catch APIError.canonicalConflict(_, let undoUnavailable) {
                do {
                    let snapshot = try await apiClient.fetchAuthoritativeSnapshot()
                    applyAuthoritativeSnapshot(snapshot)
                } catch {
                    self.error = "Unable to reload the authoritative profile after a conflict."
                }
                if undoUnavailable {
                    storage.removeCanonicalDecision(operationId: command.operationId)
                    pendingUndo = nil
                    canonicalStatusMessage = "That decision can no longer be undone."
                } else {
                    canonicalStatusMessage = "Profile changed elsewhere. Review the saved action before retrying."
                }
                syncState = .failed
                return
            } catch {
                canonicalStatusMessage = "Saved offline — recommendations will update after sync."
                syncState = .offline
                showToast("Saved offline — recommendations will update after sync.")
                return
            }
        }

        canonicalStatusMessage = nil
        syncState = .synced
        lastSyncedAt = Date()
        if let lastApplied {
            if lastApplied.actionType == .undoDecision {
                showToast("Undone.")
            } else {
                showToast(message(for: lastApplied.actionType), actionTitle: "Undo") { [weak self] in
                    self?.undoLastDecision()
                }
            }
        }
    }

    @discardableResult
    func applyCanonicalResponse(
        _ response: CanonicalDecisionResponse,
        for command: CanonicalDecisionCommand
    ) throws -> Bool {
        guard response.operationId == command.operationId else {
            throw APIError.invalidCanonicalSnapshot("operationId does not match the submitted command")
        }
        let version = response.stateVersion
        guard response.state.stateVersion == version,
              response.profile.stateVersion == version,
              response.recommendationModel.stateVersion == version,
              response.recommendationModel.rankingMetadata.profileStateVersion == version,
              response.state.user.profile == response.profile.profile else {
            throw APIError.invalidCanonicalSnapshot("state, profile, and ranking versions must agree")
        }
        if command.actionType != .undoDecision, response.gameState == nil {
            throw APIError.invalidCanonicalSnapshot("a taste action response must contain gameState")
        }
        if compareStateVersions(version, stateVersion) == .orderedAscending {
            return false
        }

        let undoTarget = command.actionType == .undoDecision ? nil : command.operationId
        let undoGameId = command.actionType == .undoDecision ? nil : command.gameId
        let snapshot = AuthoritativeSnapshot(
            stateVersion: version,
            profile: response.profile.profile,
            gameStates: response.state.user.gameStates,
            recommendationModel: response.recommendationModel,
            onboarding: response.state.user.onboarding,
            onboardingCompletedAt: response.state.user.onboardingCompletedAt,
            lastUpdatedAt: response.state.user.lastUpdatedAt,
            undoTargetOperationId: undoTarget,
            undoGameId: undoGameId
        )
        applyAuthoritativeSnapshot(snapshot)
        if let undoTarget, let undoGameId {
            pendingUndo = .canonical(targetOperationId: undoTarget, gameId: undoGameId)
        } else {
            pendingUndo = nil
        }
        return true
    }

    func applyAuthoritativeSnapshot(_ snapshot: AuthoritativeSnapshot) {
        guard compareStateVersions(snapshot.stateVersion, stateVersion) != .orderedAscending else {
            return
        }
        stateVersion = snapshot.stateVersion
        profile = snapshot.profile
        gameStates = snapshot.gameStates
        rankingMetadata = snapshot.recommendationModel.rankingMetadata
        onboardingLikedGameIds = snapshot.onboarding.likedGameIds
        onboardingDislikedGameIds = snapshot.onboarding.dislikedGameIds
        onboardingCompletedAt = snapshot.onboardingCompletedAt
        onboardingCompleted = snapshot.onboardingCompletedAt != nil
        selectedPlatformIds = Set(snapshot.onboarding.platforms.compactMap { platform in
            ["available", "limited"].contains(platform.status) ? platform.platformId : nil
        })

        let model = snapshot.recommendationModel
        pool = [model.primary].compactMap { $0 } + model.alternatives
        stablePrimaryId = model.primary?.game.id
        excludedIds = []
        pickIds = Set(model.savedPickIds)
        pickRecommendations = pickRecommendations.filter { pickIds.contains($0.game.id) }
        for recommendation in pool + pickRecommendations {
            gamesCache[recommendation.game.id] = recommendation.game
        }
        pendingUndo = snapshot.undoTargetOperationId.flatMap { target in
            snapshot.undoGameId.map { .canonical(targetOperationId: target, gameId: $0) }
        }
        hasAuthoritativeSnapshot = true
        error = nil

        storage.removePendingActions()
        storage.saveAuthoritativeSnapshot(snapshot)
        storage.saveProfile(
            snapshot.profile,
            platformIds: selectedPlatformIds,
            onboardingCompleted: onboardingCompleted
        )
        storage.saveOnboardingMetadata(
            likedIds: onboardingLikedGameIds,
            dislikedIds: onboardingDislikedGameIds,
            completedAt: onboardingCompletedAt
        )
        for (gameId, state) in snapshot.gameStates {
            storage.saveGameState(gameId: gameId, state: state)
        }
        storage.cacheRecommendations(uniqueRecommendations(pool + pickRecommendations))
    }

    private func compareStateVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let normalizedLeft = lhs.drop(while: { $0 == "0" })
        let normalizedRight = rhs.drop(while: { $0 == "0" })
        if normalizedLeft.count != normalizedRight.count {
            return normalizedLeft.count < normalizedRight.count ? .orderedAscending : .orderedDescending
        }
        if normalizedLeft == normalizedRight { return .orderedSame }
        return normalizedLeft.lexicographicallyPrecedes(normalizedRight)
            ? .orderedAscending
            : .orderedDescending
    }

    private func message(for actionType: CanonicalDecisionActionType) -> String {
        switch actionType {
        case .started: "Started. This updates Play Next, not your taste."
        case .notForMe: "Noted. Playfit will find a better fit."
        case .loved: "Marked as loved."
        case .liked: "Marked as liked."
        case .mixed: "Marked as mixed. This records the game without changing your taste profile."
        case .dropped: "Marked as dropped. Playfit will steer away."
        case .undoDecision: "Undone."
        }
    }
}
