import Foundation
import SwiftData

@Model
public final class SDAuthoritativeSnapshot {
    @Attribute(.unique) public var id: String
    public var stateVersion: String
    public var snapshotData: Data
    public var updatedAt: Date

    public init(
        id: String = "current",
        stateVersion: String,
        snapshotData: Data,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.stateVersion = stateVersion
        self.snapshotData = snapshotData
        self.updatedAt = updatedAt
    }
}
