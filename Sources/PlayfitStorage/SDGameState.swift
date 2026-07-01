import Foundation
import SwiftData

@Model
public final class SDGameState {
    @Attribute(.unique) public var gameId: String
    public var status: String?
    public var rating: Double?
    public var inPlayfitPicks: Bool
    public var excluded: Bool
    public var updatedAt: String

    public init(
        gameId: String,
        status: String? = nil,
        rating: Double? = nil,
        inPlayfitPicks: Bool = false,
        excluded: Bool = false,
        updatedAt: String = ""
    ) {
        self.gameId = gameId
        self.status = status
        self.rating = rating
        self.inPlayfitPicks = inPlayfitPicks
        self.excluded = excluded
        self.updatedAt = updatedAt
    }
}
