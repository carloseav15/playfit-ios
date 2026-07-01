import Foundation
import SwiftData

@Model
public final class SDPendingAction {
    @Attribute(.unique) public var id: String
    public var gameId: String
    public var actionType: String
    public var payload: Data
    public var createdAt: Date
    public var retryCount: Int

    public init(
        id: String = UUID().uuidString,
        gameId: String,
        actionType: String,
        payload: Data,
        createdAt: Date = Date(),
        retryCount: Int = 0
    ) {
        self.id = id
        self.gameId = gameId
        self.actionType = actionType
        self.payload = payload
        self.createdAt = createdAt
        self.retryCount = retryCount
    }
}
