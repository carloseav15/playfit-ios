import Foundation
import SwiftData

@Model
public final class SDProfile {
    public var summary: String
    public var likedGenres: [String]
    public var avoidedGenres: [String]
    public var likedTagsData: Data
    public var dislikedTagsData: Data
    public var ratedCount: Int
    public var selectedPlatformIds: [String]
    public var onboardingCompleted: Bool
    public var signalsData: Data

    public init(
        summary: String = "",
        likedGenres: [String] = [],
        avoidedGenres: [String] = [],
        likedTags: [String: Int] = [:],
        dislikedTags: [String: Int] = [:],
        ratedCount: Int = 0,
        selectedPlatformIds: [String] = [],
        onboardingCompleted: Bool = false,
        signals: [String] = []
    ) {
        self.summary = summary
        self.likedGenres = likedGenres
        self.avoidedGenres = avoidedGenres
        self.likedTagsData = (try? JSONEncoder().encode(likedTags)) ?? Data()
        self.dislikedTagsData = (try? JSONEncoder().encode(dislikedTags)) ?? Data()
        self.ratedCount = ratedCount
        self.selectedPlatformIds = selectedPlatformIds
        self.onboardingCompleted = onboardingCompleted
        self.signalsData = Data()
    }

    public var likedTags: [String: Int] {
        get { (try? JSONDecoder().decode([String: Int].self, from: likedTagsData)) ?? [:] }
        set { likedTagsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    public var dislikedTags: [String: Int] {
        get { (try? JSONDecoder().decode([String: Int].self, from: dislikedTagsData)) ?? [:] }
        set { dislikedTagsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
}
