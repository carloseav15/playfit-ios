import PlayfitModels
import SwiftUI

public struct SignalSummaryBar: View {
    let preferencesCount: Int
    let likedCount: Int
    let avoidedCount: Int

    public init(preferencesCount: Int, likedCount: Int, avoidedCount: Int) {
        self.preferencesCount = preferencesCount
        self.likedCount = likedCount
        self.avoidedCount = avoidedCount
    }

    public var body: some View {
        Text("\(preferencesCount) preferences / \(likedCount) liked / \(avoidedCount) avoided")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
