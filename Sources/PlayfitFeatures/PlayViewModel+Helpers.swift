import PlayfitLogic
import PlayfitModels

extension PlayViewModel {
    func isTerminal(_ status: PlayStatus) -> Bool {
        [.completed, .beaten, .abandoned, .dropped].contains(status)
    }

    func activePickIds(in states: [String: UserGameState]) -> Set<String> {
        Set(states.compactMap { gameId, state in
            guard state.inPlayfitPicks,
                  !state.excluded,
                  state.status.map({ !isTerminal($0) }) ?? true else { return nil }
            return gameId
        })
    }

    func uniqueRecommendations(_ recommendations: [RankedRecommendation]) -> [RankedRecommendation] {
        var seen = Set<String>()
        return recommendations.filter { seen.insert($0.game.id).inserted }
    }

    func rebuildProfileFromCurrentSignals() {
        profile = rebuildUserProfile(
            onboardingLikedIds: onboardingLikedGameIds,
            onboardingDislikedIds: onboardingDislikedGameIds,
            gameStates: gameStates,
            gamesCache: gamesCache
        )
        storage.saveProfile(profile, platformIds: selectedPlatformIds, onboardingCompleted: onboardingCompleted)
    }
}
