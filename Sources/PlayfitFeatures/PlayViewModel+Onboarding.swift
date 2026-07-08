import Foundation
import PlayfitAPI
import PlayfitLogic
import PlayfitModels

extension PlayViewModel {
    public func searchGames(query: String) async throws -> [Game] {
        guard let apiClient else { throw APIError.unexpectedResponse }
        return try await apiClient.searchGames(query: query)
    }

    @MainActor
    public func completeOnboarding(
        selectedPlatformIds: Set<String>,
        likedGames: [Game],
        dislikedGame: Game?
    ) async {
        let completedAt = ISO8601DateFormatter().string(from: Date())
        onboardingLikedGameIds = likedGames.map(\.id)
        onboardingDislikedGameIds = dislikedGame.map { [$0.id] } ?? []
        onboardingCompletedAt = completedAt

        for game in likedGames {
            gamesCache[game.id] = game
            gameStates[game.id] = UserGameState(
                source: "onboarding",
                createdAt: completedAt,
                updatedAt: completedAt
            )
        }
        if let miss = dislikedGame {
            gamesCache[miss.id] = miss
            gameStates[miss.id] = UserGameState(
                source: "onboarding",
                createdAt: completedAt,
                updatedAt: completedAt
            )
        }

        let profile = rebuildUserProfile(
            onboardingLikedIds: onboardingLikedGameIds,
            onboardingDislikedIds: onboardingDislikedGameIds,
            gameStates: gameStates,
            gamesCache: gamesCache
        )
        self.profile = profile
        self.selectedPlatformIds = selectedPlatformIds
        onboardingCompleted = true

        storage.saveProfile(profile, platformIds: selectedPlatformIds, onboardingCompleted: true)
        storage.saveOnboardingMetadata(
            likedIds: onboardingLikedGameIds,
            dislikedIds: onboardingDislikedGameIds,
            completedAt: completedAt
        )

        try? await syncProfileToServer()
    }
}
