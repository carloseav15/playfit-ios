import Foundation
import PlayfitModels

public enum MockPlayfitData {

    public static let rankedRecommendations: [RankedRecommendation] = [
        RankedRecommendation(
            game: Game(
                id: "metroid_prime_remastered",
                title: "Metroid Prime Remastered",
                platforms: ["Nintendo Switch"],
                genres: ["Adventure", "Shooter"],
                tags: ["Atmospheric", "Exploration", "Tight pacing"],
                criticScore: 94,
                playtimeHours: 14,
                series: "Metroid",
                primaryGenre: "Adventure",
                coverPath: "metroid_prime_remastered",
                releaseYear: "2023",
                availablePlatformIds: ["switch"],
                availablePlatformNames: ["Nintendo Switch"]
            ),
            affinityScore: 94,
            riskScore: 18,
            confidence: .high,
            fitReasons: [
                "Strong history with atmospheric",
                "Genre match: Adventure",
                "Strong history with exploration",
            ],
            cautionReasons: [],
            platformAvailability: .available,
            accessStatus: .playable,
            inPlayfitPicks: true
        ),
        RankedRecommendation(
            game: Game(
                id: "hades",
                title: "Hades",
                platforms: ["Nintendo Switch", "PC", "PlayStation 5"],
                genres: ["Action", "Roguelite"],
                tags: ["Fast sessions", "Build crafting", "Narrative"],
                criticScore: 93,
                playtimeHours: 24,
                series: "Hades",
                primaryGenre: "Action",
                coverPath: "hades",
                releaseYear: "2020",
                availablePlatformIds: ["switch", "pc", "ps5"],
                availablePlatformNames: ["Nintendo Switch", "PC", "PlayStation 5"]
            ),
            affinityScore: 89,
            riskScore: 22,
            confidence: .high,
            fitReasons: [
                "Strong history with build crafting",
                "Strong history with narrative",
            ],
            cautionReasons: [
                "Difficulty curve may get in the way",
            ],
            platformAvailability: .available,
            accessStatus: .playable
        ),
        RankedRecommendation(
            game: Game(
                id: "outer_wilds",
                title: "Outer Wilds",
                platforms: ["Nintendo Switch", "PC", "PlayStation 5"],
                genres: ["Adventure", "Puzzle"],
                tags: ["Mystery", "Discovery", "Systems"],
                criticScore: 85,
                playtimeHours: 18,
                series: "Outer Wilds",
                primaryGenre: "Adventure",
                coverPath: "outer_wilds",
                releaseYear: "2019",
                availablePlatformIds: ["switch", "pc", "ps5"],
                availablePlatformNames: ["Nintendo Switch", "PC", "PlayStation 5"]
            ),
            affinityScore: 86,
            riskScore: 30,
            confidence: .medium,
            fitReasons: [
                "Emerging pattern around mystery",
                "Genre match: Adventure",
            ],
            cautionReasons: [
                "No major watch-out yet.",
            ],
            platformAvailability: .available,
            accessStatus: .playable
        ),
    ]

    public static let userProfile = UserProfile(
        summary: "Adventurer who enjoys atmospheric worlds with tight pacing.",
        likedGenres: ["Adventure", "RPG", "Action"],
        avoidedGenres: ["Horror", "Sports"],
        likedTags: ["exploration": 3, "atmospheric": 2, "narrative": 2],
        dislikedTags: ["horror": 1],
        ratedCount: 12,
        signals: [
            ProfileSignal(
                id: "exploration",
                tone: .positive,
                label: "Exploration",
                reason: "Consistent high ratings for exploration-heavy games"
            ),
            ProfileSignal(
                id: "atmospheric",
                tone: .positive,
                label: "Atmospheric",
                reason: "Prefers immersive, atmospheric worlds"
            ),
        ]
    )
}
