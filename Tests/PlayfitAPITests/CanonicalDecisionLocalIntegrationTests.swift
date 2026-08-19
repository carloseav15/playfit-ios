import Foundation
@testable import PlayfitAPI
import PlayfitModels
import XCTest

final class CanonicalDecisionLocalIntegrationTests: XCTestCase {
    func testNotForMeThenUndoAgainstLocalAPIAndSupabase() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard environment["PLAYFIT_LOCAL_INTEGRATION"] == "1" else {
            throw XCTSkip("Set PLAYFIT_LOCAL_INTEGRATION=1 to run the local Supabase/API flow.")
        }
        let baseURL = try XCTUnwrap(URL(string: environment["PLAYFIT_LOCAL_APP_URL"] ?? ""))
        let accessToken = try XCTUnwrap(environment["PLAYFIT_LOCAL_ACCESS_TOKEN"])
        let userId = try XCTUnwrap(environment["PLAYFIT_LOCAL_USER_ID"])

        let client = HTTPPlayfitClient(baseURL: baseURL)
        client.setAuthSession(AuthSession(
            accessToken: accessToken,
            refreshToken: "local-integration-refresh-token",
            expiresAt: Date().addingTimeInterval(3600),
            userId: userId,
            email: nil
        ))
        try await Task.sleep(for: .milliseconds(100))

        let decisionOperationId = UUID().uuidString.lowercased()
        let decision = try await client.submitCanonicalDecision(CanonicalDecisionCommand(
            operationId: decisionOperationId,
            expectedStateVersion: "1",
            actionType: .notForMe,
            gameId: "action-game"
        ))

        XCTAssertEqual(decision.stateVersion, "2")
        XCTAssertEqual(decision.profile.stateVersion, "2")
        XCTAssertEqual(decision.gameState?.rating, 2)
        XCTAssertEqual(decision.recommendationModel.rankingMetadata.profileStateVersion, "2")

        let undo = try await client.submitCanonicalDecision(CanonicalDecisionCommand(
            expectedStateVersion: "2",
            actionType: .undoDecision,
            targetOperationId: decisionOperationId
        ))

        XCTAssertEqual(undo.stateVersion, "3")
        XCTAssertEqual(undo.profile.stateVersion, "3")
        XCTAssertEqual(undo.undo?.targetOperationId, decisionOperationId)
        XCTAssertEqual(undo.recommendationModel.rankingMetadata.profileStateVersion, "3")
    }
}
