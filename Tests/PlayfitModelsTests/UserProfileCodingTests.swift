import Foundation
import PlayfitModels
import XCTest

final class UserProfileCodingTests: XCTestCase {
    func testResolvesCoverURLUsingBackendFieldsBeforeCatalogFallback() {
        let baseURL = URL(string: "https://playfit.test")!
        let external = Game(
            id: "celeste",
            title: "Celeste",
            coverURL: URL(string: "https://images.test/celeste.jpg"),
            coverPath: "/covers/games/ignored.jpg"
        )
        let relative = Game(
            id: "hades",
            title: "Hades",
            coverPath: "/covers/games/hades.webp"
        )
        let fallback = Game(id: "outer_wilds", title: "Outer Wilds")

        XCTAssertEqual(
            external.resolvedCoverURL(baseURL: baseURL)?.absoluteString,
            "https://images.test/celeste.jpg"
        )
        XCTAssertEqual(
            relative.resolvedCoverURL(baseURL: baseURL)?.absoluteString,
            "https://playfit.test/covers/games/hades.webp"
        )
        XCTAssertEqual(
            fallback.resolvedCoverURL(baseURL: baseURL)?.absoluteString,
            "https://playfit.test/covers/games/outer_wilds.jpg"
        )
    }

    func testDecodesCanonicalCamelCaseProfile() throws {
        let data = Data(#"{"summary":"Stable","likedGenres":["Action"],"avoidedGenres":["Horror"],"likedTags":{"short":2},"dislikedTags":{"grindy":1},"ratedCount":3,"signals":[]}"#.utf8)

        let profile = try JSONDecoder().decode(UserProfile.self, from: data)

        XCTAssertEqual(profile.likedGenres, ["Action"])
        XCTAssertEqual(profile.avoidedGenres, ["Horror"])
        XCTAssertEqual(profile.likedTags, ["short": 2])
        XCTAssertEqual(profile.dislikedTags, ["grindy": 1])
        XCTAssertEqual(profile.ratedCount, 3)
    }

    func testDecodesLegacySnakeCaseProfile() throws {
        let data = Data(#"{"summary":"Legacy","liked_genres":["Puzzle"],"avoided_genres":[],"liked_tags":{"cozy":1},"disliked_tags":{},"rated_count":1,"signals":[]}"#.utf8)

        let profile = try JSONDecoder().decode(UserProfile.self, from: data)

        XCTAssertEqual(profile.likedGenres, ["Puzzle"])
        XCTAssertEqual(profile.likedTags, ["cozy": 1])
        XCTAssertEqual(profile.ratedCount, 1)
    }

    func testEncodesCanonicalCamelCaseKeys() throws {
        let profile = UserProfile(likedGenres: ["RPG"], ratedCount: 2)
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(profile)) as? [String: Any]
        )

        XCTAssertNotNil(object["likedGenres"])
        XCTAssertNotNil(object["ratedCount"])
        XCTAssertNil(object["liked_genres"])
        XCTAssertNil(object["rated_count"])
    }
}
