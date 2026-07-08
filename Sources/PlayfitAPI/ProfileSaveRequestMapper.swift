import Foundation
import PlayfitModels

enum ProfileSaveRequestMapper {
    static func makeBody(
        deviceID: String,
        profile: UserProfile,
        gameStates: [String: UserGameState],
        onboarding: OnboardingPayload
    ) -> ProfileSaveBody {
        let now = ISO8601DateFormatter().string(from: Date())
        let mappedStates = Dictionary(uniqueKeysWithValues: gameStates.map { gameId, state in
            (
                gameId,
                ProfileSaveGameState(
                    gameId: gameId,
                    title: "",
                    inBacklog: state.inBacklog,
                    inWishlist: state.inWishlist,
                    inPlayfitPicks: state.inPlayfitPicks,
                    source: state.source.isEmpty ? "manual" : state.source,
                    createdAt: state.createdAt.isEmpty ? now : state.createdAt,
                    updatedAt: state.updatedAt.isEmpty ? now : state.updatedAt,
                    rating: state.rating,
                    status: state.status?.rawValue,
                    excluded: state.excluded ? true : nil
                )
            )
        })

        return ProfileSaveBody(
            deviceId: deviceID,
            gameStates: mappedStates,
            profile: ProfileSaveProfile(
                summary: profile.summary,
                likedGenres: profile.likedGenres,
                avoidedGenres: profile.avoidedGenres,
                likedTags: profile.likedTags,
                dislikedTags: profile.dislikedTags,
                ratedCount: profile.ratedCount,
                signals: profile.signals.map {
                    ProfileSaveSignal(id: $0.id, tone: $0.tone.rawValue, label: $0.label, reason: $0.reason)
                }
            ),
            onboarding: ProfileSaveOnboarding(
                step: onboarding.step,
                platforms: onboarding.platforms.map {
                    ProfileSavePlatform(platformId: $0, status: "available")
                },
                likedGameIds: onboarding.likedGameIds,
                dislikedGameIds: onboarding.dislikedGameIds,
                onboardingCompletedAt: onboarding.onboardingCompletedAt
            )
        )
    }
}

struct ProfileSaveBody: Encodable {
    let deviceId: String?
    let gameStates: [String: ProfileSaveGameState]
    let profile: ProfileSaveProfile?
    let onboarding: ProfileSaveOnboarding
}

struct ProfileSaveGameState: Encodable {
    let gameId: String
    let title: String
    let inBacklog: Bool
    let inWishlist: Bool
    let inPlayfitPicks: Bool
    let source: String
    let createdAt: String
    let updatedAt: String
    let rating: Double?
    let status: String?
    let excluded: Bool?
}

struct ProfileSaveProfile: Encodable {
    let summary: String
    let likedGenres: [String]
    let avoidedGenres: [String]
    let likedTags: [String: Int]
    let dislikedTags: [String: Int]
    let ratedCount: Int
    let signals: [ProfileSaveSignal]
}

struct ProfileSaveSignal: Encodable {
    let id: String
    let tone: String
    let label: String
    let reason: String
}

struct ProfileSaveOnboarding: Encodable {
    let step: String
    let platforms: [ProfileSavePlatform]
    let likedGameIds: [String]
    let dislikedGameIds: [String]
    let onboardingCompletedAt: String?

    enum CodingKeys: String, CodingKey {
        case step
        case platforms
        case likedGameIds
        case dislikedGameIds
        case onboardingCompletedAt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(step, forKey: .step)
        try container.encode(platforms, forKey: .platforms)
        try container.encode(likedGameIds, forKey: .likedGameIds)
        try container.encode(dislikedGameIds, forKey: .dislikedGameIds)
        try container.encode(onboardingCompletedAt, forKey: .onboardingCompletedAt)
    }
}

struct ProfileSavePlatform: Encodable {
    let platformId: String
    let status: String
}
