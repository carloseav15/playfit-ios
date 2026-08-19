import Foundation
@testable import PlayfitAPI
import PlayfitModels
import XCTest

final class CanonicalDecisionContractTests: XCTestCase {
    func testDecodesExactCanonicalDecisionResponseFixture() throws {
        let url = try XCTUnwrap(Bundle.module.url(
            forResource: "canonical-decision-response",
            withExtension: "json"
        ))
        let response = try JSONDecoder().decode(
            CanonicalDecisionResponse.self,
            from: Data(contentsOf: url)
        )

        XCTAssertEqual(response.stateVersion, "6")
        XCTAssertEqual(response.state.stateVersion, "6")
        XCTAssertEqual(response.profile.stateVersion, "6")
        XCTAssertEqual(response.gameState?.rating, 5)
        XCTAssertEqual(response.recommendationModel.stateVersion, "6")
        XCTAssertEqual(response.recommendationModel.rankingMetadata.profileStateVersion, "6")
        XCTAssertEqual(response.recommendationModel.rankingMetadata.candidates.first?.gameId, "celeste")
    }

    func testDecodesExactCanonicalUndoResponseFixture() throws {
        let url = try XCTUnwrap(Bundle.module.url(
            forResource: "canonical-undo-response",
            withExtension: "json"
        ))
        let response = try JSONDecoder().decode(
            CanonicalDecisionResponse.self,
            from: Data(contentsOf: url)
        )

        XCTAssertEqual(response.stateVersion, "7")
        XCTAssertNil(response.gameState)
        XCTAssertEqual(response.undo?.targetOperationId, "660e8400-e29b-41d4-a716-446655440000")
        XCTAssertEqual(response.recommendationModel.rankingMetadata.profileStateVersion, "7")
    }

    func testCanonicalCommandEncodesOnlyTheStrictBackendFields() throws {
        let command = CanonicalDecisionCommand(
            operationId: "660e8400-e29b-41d4-a716-446655440000",
            expectedStateVersion: "5",
            actionType: .liked,
            gameId: "hades",
            played: true
        )
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(command)) as? [String: Any]
        )

        XCTAssertEqual(Set(object.keys), [
            "operationId", "expectedStateVersion", "actionType", "gameId", "played",
        ])
        XCTAssertEqual(object["actionType"] as? String, "liked")
        XCTAssertNil(object["targetOperationId"])
    }

    func testStartedCommandDoesNotEncodeTasteFields() throws {
        let command = CanonicalDecisionCommand(
            operationId: "660e8400-e29b-41d4-a716-446655440000",
            expectedStateVersion: "5",
            actionType: .started,
            gameId: "hades"
        )
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(command)) as? [String: Any]
        )

        XCTAssertEqual(Set(object.keys), ["operationId", "expectedStateVersion", "actionType", "gameId"])
        XCTAssertEqual(object["actionType"] as? String, "started")
        XCTAssertNil(object["played"])
    }
}
