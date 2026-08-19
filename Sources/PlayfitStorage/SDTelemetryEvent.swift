import Foundation
import SwiftData

@Model
public final class SDTelemetryEvent {
    @Attribute(.unique) public var eventId: String
    public var eventName: String
    public var recommendationId: String
    public var stateVersion: String
    public var gameId: String
    public var rank: Int
    public var sequence: Int
    public var createdAt: Date

    public init(eventId: String, eventName: String, recommendationId: String, stateVersion: String, gameId: String, rank: Int, sequence: Int) {
        self.eventId = eventId; self.eventName = eventName; self.recommendationId = recommendationId
        self.stateVersion = stateVersion; self.gameId = gameId; self.rank = rank
        self.sequence = sequence; self.createdAt = Date()
    }
}
