import Foundation
import SwiftData

@Model
public final class SDCanonicalOperation {
    @Attribute(.unique) public var operationId: String
    public var expectedStateVersion: String
    public var actionType: String
    public var gameId: String?
    public var played: Bool?
    public var targetOperationId: String?
    public var sequence: Int
    public var createdAt: Date

    public init(
        operationId: String,
        expectedStateVersion: String,
        actionType: String,
        gameId: String?,
        played: Bool?,
        targetOperationId: String?,
        sequence: Int,
        createdAt: Date = Date()
    ) {
        self.operationId = operationId
        self.expectedStateVersion = expectedStateVersion
        self.actionType = actionType
        self.gameId = gameId
        self.played = played
        self.targetOperationId = targetOperationId
        self.sequence = sequence
        self.createdAt = createdAt
    }
}
