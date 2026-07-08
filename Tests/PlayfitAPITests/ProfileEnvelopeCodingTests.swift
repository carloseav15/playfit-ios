import Foundation
@testable import PlayfitAPI
import PlayfitModels
import XCTest

final class ProfileEnvelopeCodingTests: XCTestCase {
    func testDecodesGameStatesFromBackendSnakeCaseEnvelope() throws {
        let data = Data(#"{"state":{"game_states":{"hades":{"rating":4,"inPlayfitPicks":true,"source":"manual","createdAt":"2026-01-01","updatedAt":"2026-01-02"}},"profile":{"summary":"Known","likedGenres":["Action"],"avoidedGenres":[],"likedTags":{},"dislikedTags":{},"ratedCount":1,"signals":[]},"onboarding":{"onboardingCompletedAt":"2026-01-01"}}}"#.utf8)

        let envelope = try JSONDecoder().decode(ProfileEnvelope.self, from: data)

        XCTAssertEqual(envelope.state?.gameStates?["hades"]?.rating, 4)
        XCTAssertEqual(envelope.state?.gameStates?["hades"]?.inPlayfitPicks, true)
        XCTAssertEqual(envelope.state?.profile?.likedGenres, ["Action"])
        XCTAssertEqual(envelope.state?.onboarding?.onboardingCompletedAt, "2026-01-01")
    }

    func testSessionExpiryWindow() {
        let expiring = AuthSession(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(30),
            userId: "user",
            email: nil
        )

        XCTAssertTrue(expiring.expires(within: 60))
        XCTAssertFalse(expiring.isExpired)
    }

    func testProfileSaveMapperPreservesBackendPayloadShape() throws {
        let body = ProfileSaveRequestMapper.makeBody(
            deviceID: "device-1",
            profile: UserProfile(
                summary: "Known",
                likedGenres: ["Action"],
                avoidedGenres: ["Horror"],
                likedTags: ["roguelite": 2],
                dislikedTags: ["punishing": 1],
                ratedCount: 3,
                signals: [
                    ProfileSignal(id: "tag-fit-roguelite", tone: .positive, label: "Roguelite", reason: "Shared trait")
                ]
            ),
            gameStates: [
                "hades": UserGameState(
                    status: .completed,
                    rating: 5,
                    inWishlist: false,
                    inBacklog: false,
                    inPlayfitPicks: true,
                    excluded: false,
                    source: "",
                    createdAt: "",
                    updatedAt: ""
                ),
                "elden-ring": UserGameState(
                    rating: nil,
                    excluded: true,
                    source: "manual",
                    createdAt: "2026-01-01T00:00:00Z",
                    updatedAt: "2026-01-02T00:00:00Z"
                ),
            ],
            onboarding: OnboardingPayload(
                step: "dislikes",
                platforms: ["ps5"],
                likedGameIds: ["hades"],
                dislikedGameIds: ["elden-ring"],
                onboardingCompletedAt: nil
            )
        )

        let data = try JSONEncoder().encode(body)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let gameStates = try XCTUnwrap(json["gameStates"] as? [String: Any])
        let hades = try XCTUnwrap(gameStates["hades"] as? [String: Any])
        let eldenRing = try XCTUnwrap(gameStates["elden-ring"] as? [String: Any])
        let onboarding = try XCTUnwrap(json["onboarding"] as? [String: Any])
        let platforms = try XCTUnwrap(onboarding["platforms"] as? [[String: Any]])

        XCTAssertEqual(json["deviceId"] as? String, "device-1")
        XCTAssertEqual(hades["gameId"] as? String, "hades")
        XCTAssertEqual(hades["source"] as? String, "manual")
        XCTAssertEqual(hades["status"] as? String, "completed")
        XCTAssertNil(hades["excluded"])
        XCTAssertEqual(eldenRing["excluded"] as? Bool, true)
        XCTAssertEqual(platforms.first?["platformId"] as? String, "ps5")
        XCTAssertTrue(onboarding.keys.contains("onboardingCompletedAt"))
        XCTAssert(onboarding["onboardingCompletedAt"] is NSNull)
    }
}
