import Foundation
@testable import PlayfitAPI
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
}
