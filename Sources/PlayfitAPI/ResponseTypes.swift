import Foundation
import PlayfitModels

struct ProfileState: Codable {
    let gameStates: [String: UserGameState]?
    let profile: UserProfile?
    let onboarding: OnboardingState?

    enum CodingKeys: String, CodingKey {
        case gameStates = "game_states"
        case profile
        case onboarding
    }
}

struct OnboardingState: Codable {
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
