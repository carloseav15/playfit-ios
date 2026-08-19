import Foundation
import PlayfitModels

struct ProfileState: Codable {
    let gameStates: [String: UserGameState]?
    let profile: UserProfile?
    let onboarding: PersistedOnboardingState?
    let stateVersion: String?
    let updatedAt: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case gameStates = "game_states"
        case profile
        case onboarding
        case stateVersion = "state_version"
        case updatedAt = "updated_at"
        case createdAt = "created_at"
    }
}

struct PersistedOnboardingState: Codable {
    let step: String?
    let platforms: [CanonicalPlatformSelection]?
    let likedGameIds: [String]?
    let dislikedGameIds: [String]?
    let onboardingCompletedAt: String?
}

struct ProfileEnvelope: Codable {
    let state: ProfileState?
}

struct RefreshTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Double
    let user: RefreshUser?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case user
    }
}

struct RefreshUser: Decodable {
    let id: String
    let email: String?
}

struct GameSearchResponse: Codable {
    let games: [Game]
}

struct PlatformsResponse: Codable {
    let platforms: [Platform]
}

struct ProfileSaveResponse: Decodable {
    let stateVersion: String
}

struct CanonicalConflictResponse: Decodable {
    let conflict: Bool?
    let needsResync: Bool?
    let undoUnavailable: Bool?
    let currentStateVersion: String?
    let error: String?
}
