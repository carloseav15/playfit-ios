import Foundation
import SwiftData

@Model
public final class SDCachedRecommendation {
    @Attribute(.unique) public var gameId: String
    public var rankJSON: Data
    public var cachedAt: Date

    public init(gameId: String, rankJSON: Data, cachedAt: Date = Date()) {
        self.gameId = gameId
        self.rankJSON = rankJSON
        self.cachedAt = cachedAt
    }
}
