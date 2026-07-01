import Foundation

public struct Game: Identifiable, Hashable, Sendable {
    public let id: String
    public var title: String
    public var coverURL: URL?
    public var platforms: [String]
    public var genres: [String]
    public var tags: [String]
    public var criticScore: Double?
    public var playtimeHours: Int?
    public var series: String
    public var primaryGenre: String
    public var coverPath: String
    public var releaseYear: String?
    public var releaseState: ReleaseState
    public var availablePlatformIds: [String]
    public var availablePlatformNames: [String]
    public var aliases: [String]

    public init(
        id: String,
        title: String,
        coverURL: URL? = nil,
        platforms: [String] = [],
        genres: [String] = [],
        tags: [String] = [],
        criticScore: Double? = nil,
        playtimeHours: Int? = nil,
        series: String = "",
        primaryGenre: String = "",
        coverPath: String = "",
        releaseYear: String? = nil,
        releaseState: ReleaseState = .released,
        availablePlatformIds: [String] = [],
        availablePlatformNames: [String] = [],
        aliases: [String] = []
    ) {
        self.id = id
        self.title = title
        self.coverURL = coverURL
        self.platforms = platforms
        self.genres = genres
        self.tags = tags
        self.criticScore = criticScore
        self.playtimeHours = playtimeHours
        self.series = series
        self.primaryGenre = primaryGenre
        self.coverPath = coverPath
        self.releaseYear = releaseYear
        self.releaseState = releaseState
        self.availablePlatformIds = availablePlatformIds
        self.availablePlatformNames = availablePlatformNames
        self.aliases = aliases
    }
}

extension Game: Codable {
    enum CodingKeys: String, CodingKey {
        case id = "gameId"
        case title
        case coverURL = "externalCoverUrl"
        case platforms
        case genres
        case tags
        case criticScore
        case playtimeHours
        case series
        case primaryGenre
        case coverPath
        case releaseYear
        case releaseState
        case availablePlatformIds
        case availablePlatformNames
        case aliases
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.coverURL = try container.decodeIfPresent(URL.self, forKey: .coverURL)
        self.platforms = try container.decodeIfPresent([String].self, forKey: .platforms) ?? []
        self.genres = try container.decodeIfPresent([String].self, forKey: .genres) ?? []
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        self.criticScore = try container.decodeIfPresent(Double.self, forKey: .criticScore)
        self.playtimeHours = try container.decodeIfPresent(Int.self, forKey: .playtimeHours)
        self.series = try container.decodeIfPresent(String.self, forKey: .series) ?? ""
        self.primaryGenre = try container.decodeIfPresent(String.self, forKey: .primaryGenre) ?? ""
        self.coverPath = try container.decodeIfPresent(String.self, forKey: .coverPath) ?? ""
        self.releaseYear = try container.decodeIfPresent(String.self, forKey: .releaseYear)
        self.releaseState = try container.decodeIfPresent(ReleaseState.self, forKey: .releaseState) ?? .released
        self.availablePlatformIds = try container.decodeIfPresent([String].self, forKey: .availablePlatformIds) ?? []
        self.availablePlatformNames = try container.decodeIfPresent([String].self, forKey: .availablePlatformNames) ?? []
        self.aliases = try container.decodeIfPresent([String].self, forKey: .aliases) ?? []
    }
}

public enum PlayStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case backlog
    case playing
    case onHold = "on_hold"
    case shelved
    case beaten
    case completed
    case abandoned
    case dropped
    case wantToPlay = "want_to_play"
}

public struct UserGameState: Hashable, Sendable {
    public var status: PlayStatus?
    public var rating: Double?
    public var isPicked: Bool
    public var inWishlist: Bool
    public var inBacklog: Bool
    public var inPlayfitPicks: Bool
    public var excluded: Bool
    public var source: String
    public var createdAt: String
    public var updatedAt: String

    public init(
        status: PlayStatus? = nil,
        rating: Double? = nil,
        isPicked: Bool = false,
        inWishlist: Bool = false,
        inBacklog: Bool = false,
        inPlayfitPicks: Bool = false,
        excluded: Bool = false,
        source: String = "manual",
        createdAt: String = "",
        updatedAt: String = ""
    ) {
        self.status = status
        self.rating = rating
        self.isPicked = isPicked
        self.inWishlist = inWishlist
        self.inBacklog = inBacklog
        self.inPlayfitPicks = inPlayfitPicks
        self.excluded = excluded
        self.source = source
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension UserGameState: Codable {
    enum CodingKeys: String, CodingKey {
        case status
        case rating
        case inWishlist
        case inBacklog
        case inPlayfitPicks
        case excluded
        case source
        case createdAt
        case updatedAt
        case gameId
        case title
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decodeIfPresent(PlayStatus.self, forKey: .status)
        self.rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        self.inWishlist = try container.decodeIfPresent(Bool.self, forKey: .inWishlist) ?? false
        self.inBacklog = try container.decodeIfPresent(Bool.self, forKey: .inBacklog) ?? false
        self.inPlayfitPicks = try container.decodeIfPresent(Bool.self, forKey: .inPlayfitPicks) ?? false
        self.excluded = try container.decodeIfPresent(Bool.self, forKey: .excluded) ?? false
        self.source = try container.decodeIfPresent(String.self, forKey: .source) ?? "manual"
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        self.updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? ""
        self.isPicked = false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(rating, forKey: .rating)
        try container.encode(inWishlist, forKey: .inWishlist)
        try container.encode(inBacklog, forKey: .inBacklog)
        try container.encode(inPlayfitPicks, forKey: .inPlayfitPicks)
        try container.encodeIfPresent(excluded, forKey: .excluded)
        try container.encode(source, forKey: .source)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }


}

public struct Platform: Codable, Identifiable, Hashable, Sendable {
    public var id: String { platformId }
    public let platformId: String
    public let displayName: String
    public let family: String
    public let kind: String
    public let activeStatus: String
    public let sortOrder: Int

    public init(
        platformId: String,
        displayName: String,
        family: String,
        kind: String = "console",
        activeStatus: String = "active",
        sortOrder: Int = 0
    ) {
        self.platformId = platformId
        self.displayName = displayName
        self.family = family
        self.kind = kind
        self.activeStatus = activeStatus
        self.sortOrder = sortOrder
    }
}



