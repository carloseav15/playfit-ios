import Foundation
import PlayfitModels

public struct OnboardingPayload: Codable, Sendable {
    public var step: String
    public var platforms: [String]
    public var likedGameIds: [String]
    public var dislikedGameIds: [String]
    public var onboardingCompletedAt: String?

    public init(
        step: String = "platforms",
        platforms: [String] = [],
        likedGameIds: [String] = [],
        dislikedGameIds: [String] = [],
        onboardingCompletedAt: String? = nil
    ) {
        self.step = step
        self.platforms = platforms
        self.likedGameIds = likedGameIds
        self.dislikedGameIds = dislikedGameIds
        self.onboardingCompletedAt = onboardingCompletedAt
    }
}

public protocol PlayfitAPIClient: AnyObject, Sendable {
    func fetchPlayNext() async throws -> PlayNextModel
    func fetchPicks() async throws -> [RankedRecommendation]
    func fetchProfile() async throws -> UserProfile?
    func fetchGameStates() async throws -> [String: UserGameState]
    func fetchOnboardingCompletedAt() async throws -> String?
    func searchGames(query: String) async throws -> [Game]
    func fetchGame(gameId: String) async throws -> Game?
    func saveGameState(gameId: String, state: UserGameState) async throws
    func saveProfile(profile: UserProfile, gameStates: [String: UserGameState], onboarding: OnboardingPayload) async throws
    func fetchPlatforms() async throws -> [Platform]
    func fetchGamesBatch(gameIds: [String]) async throws -> [Game]
    func deleteProfile() async throws
    func deleteGameState(gameId: String) async throws
    func setAuthSession(_ session: AuthSession?)
}
