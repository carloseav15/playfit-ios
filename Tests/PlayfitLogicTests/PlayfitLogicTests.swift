import PlayfitLogic
import PlayfitModels
import XCTest

final class PlayfitLogicTests: XCTestCase {
    func testSavingPickDoesNotCreateRating() {
        var states: [String: UserGameState] = [:]

        let state = setPlayfitPick(
            gameStates: &states,
            gameId: "celeste",
            picked: true,
            timestamp: "2026-01-01T00:00:00Z"
        )

        XCTAssertTrue(state.inPlayfitPicks)
        XCTAssertNil(state.rating)
        XCTAssertEqual(state.createdAt, "2026-01-01T00:00:00Z")
    }

    func testPlayedDroppedUsesTerminalNegativeMapping() {
        var states = ["hades": UserGameState(inPlayfitPicks: true)]

        let state = applyDecisionFeedback(
            gameStates: &states,
            gameId: "hades",
            feedback: .playedDropped,
            timestamp: "2026-01-01T00:00:00Z"
        )

        XCTAssertEqual(state.status, .abandoned)
        XCTAssertEqual(state.rating, 2)
        XCTAssertTrue(state.excluded)
        XCTAssertFalse(state.inPlayfitPicks)
    }

    func testStartingPickMovesItToPlaying() {
        var states = ["celeste": UserGameState(inPlayfitPicks: true)]

        let state = applyDecisionFeedback(
            gameStates: &states,
            gameId: "celeste",
            feedback: .play,
            timestamp: "2026-01-01T00:00:00Z"
        )

        XCTAssertEqual(state.status, .playing)
        XCTAssertFalse(state.inPlayfitPicks)
        XCTAssertFalse(state.inBacklog)
        XCTAssertFalse(state.excluded)
    }

    func testProfileRebuildKeepsOnboardingFavoriteSeparateFromRatings() {
        let games = [
            "celeste": Game(id: "celeste", title: "Celeste", tags: ["precision"], primaryGenre: "Platformer"),
            "hades": Game(id: "hades", title: "Hades", tags: ["roguelite"], primaryGenre: "Action"),
        ]
        let states = ["hades": UserGameState(rating: 2)]

        let profile = rebuildUserProfile(
            onboardingLikedIds: ["celeste"],
            onboardingDislikedIds: [],
            gameStates: states,
            gamesCache: games
        )

        XCTAssertEqual(profile.ratedCount, 1)
        XCTAssertTrue(profile.likedGenres.contains("Platformer"))
        XCTAssertTrue(profile.avoidedGenres.contains("Action"))
        XCTAssertEqual(profile.likedTags["precision"], 1)
        XCTAssertEqual(profile.dislikedTags["roguelite"], 1)
        XCTAssertTrue(profile.signals.contains { $0.id == "tag-fit-precision" })
        XCTAssertTrue(profile.signals.contains { $0.id == "tag-risk-roguelite" })
    }

    func testTasteTraitsIncludeOnboardingEvidence() {
        let history = [
            TasteHistoryEntry(
                gameId: "celeste",
                title: "Celeste",
                decision: "setup_favorite",
                source: "onboarding_liked",
                tone: "positive",
                traits: ["Platformer", "precision"]
            ),
        ]

        let traits = buildTasteMapTraits(historyEntries: history, profile: UserProfile())

        XCTAssertEqual(traits.first(where: { $0.id == "precision" })?.positiveCount, 1)
        XCTAssertEqual(traits.first(where: { $0.id == "precision" })?.direction, "positive")
    }
}
