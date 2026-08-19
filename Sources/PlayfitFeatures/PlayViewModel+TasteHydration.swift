import PlayfitAPI
import PlayfitModels

extension PlayViewModel {
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
            if !hasAuthoritativeSnapshot { rebuildProfileFromCurrentSignals() }
            return
        }
        guard let apiClient else {
            if !hasAuthoritativeSnapshot { rebuildProfileFromCurrentSignals() }
            return
        }

        isLoading = true
        do {
            let fetchedGames = try await apiClient.fetchGamesBatch(gameIds: missingIds)
            for game in fetchedGames {
                gamesCache[game.id] = game
            }
            if !hasAuthoritativeSnapshot { rebuildProfileFromCurrentSignals() }
        } catch {
            self.error = "Unable to sync. Changes will be saved locally."
        }
        isLoading = false
    }
}
