import Foundation

// MARK: - Enums

public enum Confidence: String, Codable, Sendable {
    case low, medium, high
}

public enum PlatformAvailability: String, Codable, Sendable {
    case available, unavailable, unknown
}

public enum GameAccessStatus: String, Codable, Sendable {
    case playable
    case notOnPlatforms = "not_on_platforms"
    case unknownPlatform = "unknown_platform"
    case unreleased
}

public enum ReleaseState: String, Codable, Sendable {
    case released, unreleased
}

public enum DecisionFeedback: String, Codable, Sendable, CaseIterable {
    case play, later, loved, liked, mixed
    case notForMe = "not_for_me"
    case playedLoved = "played_loved"
    case playedLiked = "played_liked"
    case playedMixed = "played_mixed"
    case playedDropped = "played_dropped"

    public var isPlayed: Bool {
        switch self {
        case .playedLoved, .playedLiked, .playedMixed, .playedDropped: true
        default: false
        }
    }
}

public typealias AlreadyPlayedFeedback = DecisionFeedback

public enum DecisionTone: String, Codable, Sendable {
    case positive, warning, negative, info
}

public enum ProfileSignalTone: String, Codable, Sendable {
    case positive, negative
}

public enum PendingActionType: String, Codable, Sendable {
    case saveGameState
    case deleteGameState
}

// MARK: - Structs

public struct RankedRecommendation: Identifiable, Codable, Hashable, Sendable {
    public var id: String { game.id }
    public var game: Game
    public var affinityScore: Int
    public var riskScore: Int
    public var confidence: Confidence
    public var fitReasons: [String]
    public var cautionReasons: [String]
    public var platformAvailability: PlatformAvailability
    public var accessStatus: GameAccessStatus
    public var inBacklog: Bool
    public var inWishlist: Bool
    public var inPlayfitPicks: Bool

    public init(
        game: Game,
        affinityScore: Int,
        riskScore: Int,
        confidence: Confidence,
        fitReasons: [String] = [],
        cautionReasons: [String] = [],
        platformAvailability: PlatformAvailability = .available,
        accessStatus: GameAccessStatus = .playable,
        inBacklog: Bool = false,
        inWishlist: Bool = false,
        inPlayfitPicks: Bool = false
    ) {
        self.game = game
        self.affinityScore = affinityScore
        self.riskScore = riskScore
        self.confidence = confidence
        self.fitReasons = fitReasons
        self.cautionReasons = cautionReasons
        self.platformAvailability = platformAvailability
        self.accessStatus = accessStatus
        self.inBacklog = inBacklog
        self.inWishlist = inWishlist
        self.inPlayfitPicks = inPlayfitPicks
    }
}

public struct UserProfile: Hashable, Sendable {
    public var summary: String
    public var likedGenres: [String]
    public var avoidedGenres: [String]
    public var likedTags: [String: Int]
    public var dislikedTags: [String: Int]
    public var ratedCount: Int
    public var signals: [ProfileSignal]

    public init(
        summary: String = "",
        likedGenres: [String] = [],
        avoidedGenres: [String] = [],
        likedTags: [String: Int] = [:],
        dislikedTags: [String: Int] = [:],
        ratedCount: Int = 0,
        signals: [ProfileSignal] = []
    ) {
        self.summary = summary
        self.likedGenres = likedGenres
        self.avoidedGenres = avoidedGenres
        self.likedTags = likedTags
        self.dislikedTags = dislikedTags
        self.ratedCount = ratedCount
        self.signals = signals
    }
}

extension UserProfile: Codable {
    enum CodingKeys: String, CodingKey {
        case summary
        case likedGenres
        case avoidedGenres
        case likedTags
        case dislikedTags
        case ratedCount
        case signals
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case likedGenres = "liked_genres"
        case avoidedGenres = "avoided_genres"
        case likedTags = "liked_tags"
        case dislikedTags = "disliked_tags"
        case ratedCount = "rated_count"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
        self.summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
        self.likedGenres = try container.decodeIfPresent([String].self, forKey: .likedGenres)
            ?? legacy.decodeIfPresent([String].self, forKey: .likedGenres)
            ?? []
        self.avoidedGenres = try container.decodeIfPresent([String].self, forKey: .avoidedGenres)
            ?? legacy.decodeIfPresent([String].self, forKey: .avoidedGenres)
            ?? []
        self.likedTags = try container.decodeIfPresent([String: Int].self, forKey: .likedTags)
            ?? legacy.decodeIfPresent([String: Int].self, forKey: .likedTags)
            ?? [:]
        self.dislikedTags = try container.decodeIfPresent([String: Int].self, forKey: .dislikedTags)
            ?? legacy.decodeIfPresent([String: Int].self, forKey: .dislikedTags)
            ?? [:]
        self.ratedCount = try container.decodeIfPresent(Int.self, forKey: .ratedCount)
            ?? legacy.decodeIfPresent(Int.self, forKey: .ratedCount)
            ?? 0
        self.signals = try container.decodeIfPresent([ProfileSignal].self, forKey: .signals) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(summary, forKey: .summary)
        try container.encode(likedGenres, forKey: .likedGenres)
        try container.encode(avoidedGenres, forKey: .avoidedGenres)
        try container.encode(likedTags, forKey: .likedTags)
        try container.encode(dislikedTags, forKey: .dislikedTags)
        try container.encode(ratedCount, forKey: .ratedCount)
        try container.encode(signals, forKey: .signals)
    }
}

public struct ProfileSignal: Hashable, Sendable {
    public var id: String
    public var tone: ProfileSignalTone
    public var label: String
    public var reason: String

    public init(id: String, tone: ProfileSignalTone, label: String, reason: String) {
        self.id = id
        self.tone = tone
        self.label = label
        self.reason = reason
    }
}

extension ProfileSignal: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case tone
        case label
        case reason
    }
}

public struct RankingCandidate: Codable, Hashable, Sendable {
    public var gameId: String
    public var rank: Int

    public init(gameId: String, rank: Int) {
        self.gameId = gameId
        self.rank = rank
    }
}

public struct RankingMetadata: Codable, Hashable, Sendable {
    public var profileStateVersion: String
    public var candidates: [RankingCandidate]

    public init(profileStateVersion: String = "", candidates: [RankingCandidate] = []) {
        self.profileStateVersion = profileStateVersion
        self.candidates = candidates
    }
}

public struct PlayNextModel: Codable, Sendable {
    public var primary: RankedRecommendation?
    public var alternatives: [RankedRecommendation]
    public var savedPickIds: [String]
    public var stateVersion: String
    public var rankingMetadata: RankingMetadata

    public init(
        primary: RankedRecommendation? = nil,
        alternatives: [RankedRecommendation] = [],
        savedPickIds: [String] = [],
        stateVersion: String = "",
        rankingMetadata: RankingMetadata = RankingMetadata()
    ) {
        self.primary = primary
        self.alternatives = alternatives
        self.savedPickIds = savedPickIds
        self.stateVersion = stateVersion
        self.rankingMetadata = rankingMetadata
    }

    enum CodingKeys: String, CodingKey {
        case primary
        case alternatives
        case savedPickIds
        case stateVersion
        case rankingMetadata
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        primary = try container.decodeIfPresent(RankedRecommendation.self, forKey: .primary)
        alternatives = try container.decodeIfPresent([RankedRecommendation].self, forKey: .alternatives) ?? []
        savedPickIds = try container.decodeIfPresent([String].self, forKey: .savedPickIds) ?? []
        stateVersion = try container.decodeIfPresent(String.self, forKey: .stateVersion) ?? ""
        rankingMetadata = try container.decodeIfPresent(RankingMetadata.self, forKey: .rankingMetadata)
            ?? RankingMetadata(profileStateVersion: stateVersion)
    }
}

public enum CanonicalDecisionActionType: String, Codable, Sendable {
    case started
    case notForMe = "not_for_me"
    case loved
    case liked
    case mixed
    case dropped
    case undoDecision = "undo_decision"
}

public struct CanonicalDecisionCommand: Codable, Hashable, Sendable {
    public var operationId: String
    public var expectedStateVersion: String
    public var actionType: CanonicalDecisionActionType
    public var gameId: String?
    public var played: Bool?
    public var targetOperationId: String?

    public init(
        operationId: String = UUID().uuidString.lowercased(),
        expectedStateVersion: String,
        actionType: CanonicalDecisionActionType,
        gameId: String? = nil,
        played: Bool? = nil,
        targetOperationId: String? = nil
    ) {
        self.operationId = operationId
        self.expectedStateVersion = expectedStateVersion
        self.actionType = actionType
        self.gameId = gameId
        self.played = played
        self.targetOperationId = targetOperationId
    }
}

public struct CanonicalVersionedProfile: Codable, Hashable, Sendable {
    public var profile: UserProfile
    public var stateVersion: String

    enum CodingKeys: String, CodingKey {
        case stateVersion
    }

    public init(profile: UserProfile, stateVersion: String) {
        self.profile = profile
        self.stateVersion = stateVersion
    }

    public init(from decoder: Decoder) throws {
        profile = try UserProfile(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stateVersion = try container.decode(String.self, forKey: .stateVersion)
    }

    public func encode(to encoder: Encoder) throws {
        try profile.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stateVersion, forKey: .stateVersion)
    }
}

public struct CanonicalPlatformSelection: Codable, Hashable, Sendable {
    public var platformId: String
    public var status: String

    public init(platformId: String, status: String) {
        self.platformId = platformId
        self.status = status
    }
}

public struct CanonicalOnboardingState: Codable, Hashable, Sendable {
    public var step: String
    public var platforms: [CanonicalPlatformSelection]
    public var likedGameIds: [String]
    public var dislikedGameIds: [String]

    public init(
        step: String,
        platforms: [CanonicalPlatformSelection],
        likedGameIds: [String],
        dislikedGameIds: [String]
    ) {
        self.step = step
        self.platforms = platforms
        self.likedGameIds = likedGameIds
        self.dislikedGameIds = dislikedGameIds
    }
}

public struct CanonicalUserState: Codable, Hashable, Sendable {
    public var onboarding: CanonicalOnboardingState
    public var onboardingCompletedAt: String?
    public var profile: UserProfile?
    public var gameStates: [String: UserGameState]
    public var lastUpdatedAt: String?

    public init(
        onboarding: CanonicalOnboardingState,
        onboardingCompletedAt: String?,
        profile: UserProfile?,
        gameStates: [String: UserGameState],
        lastUpdatedAt: String?
    ) {
        self.onboarding = onboarding
        self.onboardingCompletedAt = onboardingCompletedAt
        self.profile = profile
        self.gameStates = gameStates
        self.lastUpdatedAt = lastUpdatedAt
    }
}

public struct CanonicalProductState: Codable, Hashable, Sendable {
    public var version: Int
    public var stateVersion: String
    public var user: CanonicalUserState

    public init(version: Int, stateVersion: String, user: CanonicalUserState) {
        self.version = version
        self.stateVersion = stateVersion
        self.user = user
    }
}

public struct CanonicalUndoMetadata: Codable, Hashable, Sendable {
    public var targetOperationId: String
    public var gameId: String
    public var restoredPreviousState: Bool

    public init(targetOperationId: String, gameId: String, restoredPreviousState: Bool) {
        self.targetOperationId = targetOperationId
        self.gameId = gameId
        self.restoredPreviousState = restoredPreviousState
    }
}

public struct CanonicalDecisionResponse: Codable, Sendable {
    public var operationId: String
    public var stateVersion: String
    public var state: CanonicalProductState
    public var gameState: UserGameState?
    public var profile: CanonicalVersionedProfile
    public var recommendationModel: PlayNextModel
    public var undo: CanonicalUndoMetadata?

    public init(
        operationId: String,
        stateVersion: String,
        state: CanonicalProductState,
        gameState: UserGameState?,
        profile: CanonicalVersionedProfile,
        recommendationModel: PlayNextModel,
        undo: CanonicalUndoMetadata? = nil
    ) {
        self.operationId = operationId
        self.stateVersion = stateVersion
        self.state = state
        self.gameState = gameState
        self.profile = profile
        self.recommendationModel = recommendationModel
        self.undo = undo
    }
}

public struct AuthoritativeSnapshot: Codable, Sendable {
    public var stateVersion: String
    public var profile: UserProfile
    public var gameStates: [String: UserGameState]
    public var recommendationModel: PlayNextModel
    public var onboarding: CanonicalOnboardingState
    public var onboardingCompletedAt: String?
    public var lastUpdatedAt: String?
    public var undoTargetOperationId: String?
    public var undoGameId: String?

    public init(
        stateVersion: String,
        profile: UserProfile,
        gameStates: [String: UserGameState],
        recommendationModel: PlayNextModel,
        onboarding: CanonicalOnboardingState,
        onboardingCompletedAt: String?,
        lastUpdatedAt: String?,
        undoTargetOperationId: String? = nil,
        undoGameId: String? = nil
    ) {
        self.stateVersion = stateVersion
        self.profile = profile
        self.gameStates = gameStates
        self.recommendationModel = recommendationModel
        self.onboarding = onboarding
        self.onboardingCompletedAt = onboardingCompletedAt
        self.lastUpdatedAt = lastUpdatedAt
        self.undoTargetOperationId = undoTargetOperationId
        self.undoGameId = undoGameId
    }
}

public struct TasteHistoryEntry: Codable, Hashable, Sendable {
    public var gameId: String
    public var title: String
    public var decision: String
    public var source: String
    public var tone: String?
    public var rating: Double?
    public var status: PlayStatus?
    public var updatedAt: String?
    public var traits: [String]

    public init(
        gameId: String,
        title: String,
        decision: String,
        source: String,
        tone: String? = nil,
        rating: Double? = nil,
        status: PlayStatus? = nil,
        updatedAt: String? = nil,
        traits: [String] = []
    ) {
        self.gameId = gameId
        self.title = title
        self.decision = decision
        self.source = source
        self.tone = tone
        self.rating = rating
        self.status = status
        self.updatedAt = updatedAt
        self.traits = traits
    }
}

public struct TasteMapTrait: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var label: String
    public var kind: String
    public var positiveCount: Int
    public var negativeCount: Int
    public var netScore: Int
    public var strength: Double
    public var confidence: Confidence
    public var direction: String

    public init(
        id: String,
        label: String,
        kind: String,
        positiveCount: Int = 0,
        negativeCount: Int = 0,
        netScore: Int = 0,
        strength: Double = 0,
        confidence: Confidence = .low,
        direction: String = "neutral"
    ) {
        self.id = id
        self.label = label
        self.kind = kind
        self.positiveCount = positiveCount
        self.negativeCount = negativeCount
        self.netScore = netScore
        self.strength = strength
        self.confidence = confidence
        self.direction = direction
    }
}

public struct TasteModel: Codable, Sendable {
    public var evidenceCount: Int
    public var historyEntries: [TasteHistoryEntry]
    public var mapTraits: [TasteMapTrait]
    public var positiveCount: Int
    public var negativeCount: Int
    public var confidenceLabel: String

    public init(
        evidenceCount: Int = 0,
        historyEntries: [TasteHistoryEntry] = [],
        mapTraits: [TasteMapTrait] = [],
        positiveCount: Int = 0,
        negativeCount: Int = 0,
        confidenceLabel: String = "Still learning"
    ) {
        self.evidenceCount = evidenceCount
        self.historyEntries = historyEntries
        self.mapTraits = mapTraits
        self.positiveCount = positiveCount
        self.negativeCount = negativeCount
        self.confidenceLabel = confidenceLabel
    }
}
