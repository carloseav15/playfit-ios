import PlayfitAPI
import PlayfitModels
import PlayfitStorage
@testable import PlayfitFeatures
import XCTest

@MainActor
final class PlayfitFeaturesTests: XCTestCase {
    override func setUp() {
        super.setUp()
        LocalStorageService.shared.deleteAllLocalData()
    }

    override func tearDown() {
        LocalStorageService.shared.deleteAllLocalData()
        super.tearDown()
    }

    func testResetLocalTasteStateClearsTasteWithoutClearingAuth() {
        let session = AuthSession(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(3600),
            userId: "user-1",
            email: "user@example.com"
        )
        let recommendation = RankedRecommendation(
            game: Game(id: "hades", title: "Hades", tags: ["action"], primaryGenre: "Action"),
            affinityScore: 94,
            riskScore: 5,
            confidence: .high,
            inPlayfitPicks: true
        )
        let viewModel = PlayViewModel(recommendations: [recommendation])
        viewModel.authSession = session
        viewModel.onboardingCompleted = true
        viewModel.selectedPlatformIds = ["pc"]
        viewModel.gameStates = ["hades": UserGameState(rating: 5)]
        viewModel.onboardingLikedGameIds = ["celeste"]
        viewModel.error = "stale error"

        viewModel.resetLocalTasteState()

        XCTAssertTrue(viewModel.pool.isEmpty)
        XCTAssertTrue(viewModel.pickRecommendations.isEmpty)
        XCTAssertTrue(viewModel.gameStates.isEmpty)
        XCTAssertTrue(viewModel.selectedPlatformIds.isEmpty)
        XCTAssertFalse(viewModel.onboardingCompleted)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.authSession, session)
    }

    func testTasteMapGraphClassifiesOnboardingAndRatedGames() {
        let games = [
            "celeste": Game(id: "celeste", title: "Celeste", tags: ["precision"], primaryGenre: "Platformer"),
            "hades": Game(id: "hades", title: "Hades", tags: ["action"], primaryGenre: "Action"),
            "hollow-knight": Game(id: "hollow-knight", title: "Hollow Knight", tags: ["metroidvania"], primaryGenre: "Adventure"),
        ]
        let states = [
            "celeste": UserGameState(),
            "hades": UserGameState(rating: 5),
            "hollow-knight": UserGameState(rating: 2),
        ]

        let nodes = TasteMapGraph.makeNodes(
            gameStates: states,
            gamesCache: games,
            likedGameIds: ["celeste"],
            dislikedGameIds: []
        )

        XCTAssertEqual(nodes.first { $0.id == "celeste" }?.type, .liked)
        XCTAssertEqual(nodes.first { $0.id == "hades" }?.type, .liked)
        XCTAssertEqual(nodes.first { $0.id == "hollow-knight" }?.type, .avoided)
    }

    func testPendingSaveSurvivesFailedRetryAndIsRemovedAfterSuccess() async {
        let state = UserGameState(rating: 4, updatedAt: "2026-07-16T00:00:00Z")
        LocalStorageService.shared.enqueuePendingAction(
            gameId: "hades",
            actionType: PendingActionType.saveGameState.rawValue,
            payload: try! JSONEncoder().encode(state)
        )

        let failingClient = TestAPIClient(shouldFail: true)
        let failingViewModel = PlayViewModel(apiClient: failingClient)
        await failingViewModel.drainPendingActions()
        XCTAssertEqual(failingViewModel.pendingActionsCount, 1)

        let workingClient = TestAPIClient(shouldFail: false)
        let workingViewModel = PlayViewModel(apiClient: workingClient)
        await workingViewModel.drainPendingActions()
        XCTAssertEqual(workingViewModel.pendingActionsCount, 0)
        XCTAssertEqual(workingClient.savedStates["hades"]?.rating, 4)
    }

    func testOverlayStillPendingKeepsLocalChangeOverServerSnapshot() throws {
        let pendingState = UserGameState(rating: 5, inPlayfitPicks: true)
        LocalStorageService.shared.enqueuePendingAction(
            gameId: "hades",
            actionType: PendingActionType.saveGameState.rawValue,
            payload: try JSONEncoder().encode(pendingState)
        )
        let serverState = ["hades": UserGameState(rating: 2)]
        let viewModel = PlayViewModel()

        let merged = viewModel.overlayStillPending(on: serverState)

        XCTAssertEqual(merged["hades"]?.rating, 5)
        XCTAssertTrue(merged["hades"]?.inPlayfitPicks == true)
    }

    func testSyncSuccessUpdatesStateAndCachesRecommendations() async {
        let recommendation = RankedRecommendation(
            game: Game(id: "hades", title: "Hades", primaryGenre: "Action"),
            affinityScore: 94,
            riskScore: 5,
            confidence: .high
        )
        let client = TestAPIClient(shouldFail: false)
        client.playNextResult = PlayNextModel(primary: recommendation, stateVersion: "v1")
        client.picksResult = [recommendation]
        client.gameStatesResult = ["hades": UserGameState(rating: 5)]

        let viewModel = PlayViewModel(apiClient: client)
        await viewModel.syncIfOnline()

        XCTAssertEqual(viewModel.syncState, .synced)
        XCTAssertEqual(viewModel.primary?.game.id, "hades")
        XCTAssertEqual(viewModel.gameStates["hades"]?.rating, 5)
        XCTAssertNotNil(viewModel.lastSyncedAt)
        XCTAssertTrue(LocalStorageService.shared.loadCachedRecommendations().contains { $0.game.id == "hades" })
    }

    func testSyncFailurePreservesOfflineStateAndUserFacingError() async {
        let viewModel = PlayViewModel(apiClient: TestAPIClient(shouldFail: true))

        await viewModel.syncIfOnline()

        XCTAssertEqual(viewModel.syncState, .failed)
        XCTAssertEqual(viewModel.error, "Unable to sync. Changes will be saved locally.")
        XCTAssertFalse(viewModel.isLoading)
    }

    func testSyncResolvesNeedsResyncBySavingProfileAndRetrying() async {
        let recommendation = RankedRecommendation(
            game: Game(id: "celeste", title: "Celeste", primaryGenre: "Platformer"),
            affinityScore: 91,
            riskScore: 3,
            confidence: .high
        )
        let client = TestAPIClient(shouldFail: false)
        client.needsResyncOnce = true
        client.playNextResult = PlayNextModel(primary: recommendation, stateVersion: "v2")

        let viewModel = PlayViewModel(apiClient: client)
        await viewModel.syncIfOnline()

        XCTAssertEqual(viewModel.syncState, .synced)
        XCTAssertEqual(viewModel.primary?.game.id, "celeste")
        XCTAssertEqual(client.playNextCallCount, 2)
        XCTAssertEqual(client.saveProfileCallCount, 1)
    }

    func testLocalStorageRoundTripsProfileGameStateAndMetadata() {
        let profile = UserProfile(summary: "Action player", likedGenres: ["Action"], ratedCount: 2)
        let state = UserGameState(rating: 4, inPlayfitPicks: true)

        LocalStorageService.shared.saveProfile(profile, platformIds: ["pc"], onboardingCompleted: true)
        LocalStorageService.shared.saveGameState(gameId: "hades", state: state)
        LocalStorageService.shared.saveOnboardingMetadata(
            likedIds: ["celeste"],
            dislikedIds: ["elden-ring"],
            completedAt: "2026-07-16T00:00:00Z"
        )

        XCTAssertEqual(LocalStorageService.shared.loadProfile()?.summary, "Action player")
        XCTAssertEqual(LocalStorageService.shared.loadOnboardingStatus().platformIds, ["pc"])
        XCTAssertEqual(LocalStorageService.shared.loadGameStates()["hades"]?.rating, 4)
        XCTAssertEqual(LocalStorageService.shared.loadOnboardingMetadata().likedIds, ["celeste"])
    }

    func testCanonicalTasteActionsReplaceProfileAndPoolWithNPlusOne() async throws {
        for action in [
            CanonicalDecisionActionType.notForMe,
            .loved,
            .liked,
            .mixed,
            .dropped,
        ] {
            LocalStorageService.shared.deleteAllLocalData()
            let command = canonicalCommand(action: action, operationId: UUID().uuidString.lowercased())
            let client = TestAPIClient(shouldFail: false)
            client.canonicalResponses = [canonicalResponse(
                command: command,
                version: "6",
                profileSummary: "Server \(action.rawValue) N+1",
                primaryGameId: "celeste"
            )]
            let viewModel = PlayViewModel(
                profile: UserProfile(summary: "Client profile must not win"),
                apiClient: client
            )
            viewModel.stateVersion = "5"
            viewModel.gamesCache["hades"] = Game(
                id: "hades",
                title: "Hades",
                tags: ["client-only"],
                primaryGenre: "Client genre"
            )
            LocalStorageService.shared.enqueueCanonicalDecision(command)

            await viewModel.drainCanonicalDecisions()

            XCTAssertEqual(viewModel.stateVersion, "6")
            XCTAssertEqual(viewModel.profile.summary, "Server \(action.rawValue) N+1")
            XCTAssertEqual(viewModel.primary?.game.id, "celeste")
            XCTAssertEqual(viewModel.rankingMetadata.profileStateVersion, "6")
            XCTAssertEqual(LocalStorageService.shared.loadAuthoritativeSnapshot()?.stateVersion, "6")
            XCTAssertTrue(LocalStorageService.shared.loadCanonicalDecisions().isEmpty)
        }
    }

    func testCanonicalUndoAdvancesNToNPlusOneToNPlusTwo() async {
        let decision = canonicalCommand(action: .notForMe)
        let undo = CanonicalDecisionCommand(
            operationId: "770e8400-e29b-41d4-a716-446655440000",
            expectedStateVersion: "6",
            actionType: .undoDecision,
            targetOperationId: decision.operationId
        )
        let client = TestAPIClient(shouldFail: false)
        client.canonicalResponses = [
            canonicalResponse(
                command: decision,
                version: "6",
                profileSummary: "Decision N+1",
                primaryGameId: "celeste"
            ),
            canonicalResponse(
                command: undo,
                version: "7",
                profileSummary: "Restored N+2",
                primaryGameId: "hollow-knight",
                gameState: nil,
                undoTargetOperationId: decision.operationId
            ),
        ]
        let viewModel = PlayViewModel(apiClient: client)
        viewModel.stateVersion = "5"
        LocalStorageService.shared.enqueueCanonicalDecision(decision)

        await viewModel.drainCanonicalDecisions()
        XCTAssertEqual(viewModel.stateVersion, "6")

        LocalStorageService.shared.enqueueCanonicalDecision(undo)
        await viewModel.drainCanonicalDecisions()

        XCTAssertEqual(viewModel.stateVersion, "7")
        XCTAssertEqual(viewModel.profile.summary, "Restored N+2")
        XCTAssertEqual(viewModel.primary?.game.id, "hollow-knight")
        XCTAssertNil(viewModel.gameStates["hades"])
    }

    func testStaleCanonicalResponseCannotReplaceNewerSnapshot() throws {
        let viewModel = PlayViewModel()
        viewModel.applyAuthoritativeSnapshot(authoritativeSnapshot(
            version: "6",
            profileSummary: "Current N+1",
            primaryGameId: "celeste"
        ))
        let command = canonicalCommand(action: .loved)
        let stale = canonicalResponse(
            command: command,
            version: "5",
            profileSummary: "Stale N",
            primaryGameId: "hades"
        )

        let applied = try viewModel.applyCanonicalResponse(stale, for: command)

        XCTAssertFalse(applied)
        XCTAssertEqual(viewModel.stateVersion, "6")
        XCTAssertEqual(viewModel.profile.summary, "Current N+1")
        XCTAssertEqual(viewModel.primary?.game.id, "celeste")
    }

    func testConflictResyncsWithoutOverwriteOrSilentRetry() async {
        let command = canonicalCommand(action: .liked)
        let client = TestAPIClient(shouldFail: false)
        client.conflictOnNextSubmit = true
        client.authoritativeSnapshotResult = authoritativeSnapshot(
            version: "7",
            profileSummary: "Other session N+2",
            primaryGameId: "ori"
        )
        let viewModel = PlayViewModel(apiClient: client)
        viewModel.stateVersion = "5"
        LocalStorageService.shared.enqueueCanonicalDecision(command)

        await viewModel.drainCanonicalDecisions()

        XCTAssertEqual(viewModel.stateVersion, "7")
        XCTAssertEqual(viewModel.profile.summary, "Other session N+2")
        XCTAssertEqual(client.submittedCommands.count, 1)
        XCTAssertEqual(LocalStorageService.shared.loadCanonicalDecisions().map(\.operationId), [command.operationId])
    }

    func testTimeoutRetryReusesTheSameOperationId() async {
        let command = canonicalCommand(action: .loved)
        let client = TestAPIClient(shouldFail: false)
        client.submitFailuresRemaining = 1
        client.canonicalResponses = [canonicalResponse(
            command: command,
            version: "6",
            profileSummary: "Applied once",
            primaryGameId: "celeste"
        )]
        let viewModel = PlayViewModel(apiClient: client)
        viewModel.stateVersion = "5"
        LocalStorageService.shared.enqueueCanonicalDecision(command)

        await viewModel.drainCanonicalDecisions()
        XCTAssertEqual(LocalStorageService.shared.loadCanonicalDecisions().count, 1)
        await viewModel.drainCanonicalDecisions()

        XCTAssertEqual(client.submittedCommands.map(\.operationId), [command.operationId, command.operationId])
        XCTAssertEqual(viewModel.stateVersion, "6")
        XCTAssertTrue(LocalStorageService.shared.loadCanonicalDecisions().isEmpty)
    }

    func testOfflineCanonicalQueueReplaysInOrderAndRebasesOnlyAfterEachSnapshot() async {
        let first = canonicalCommand(
            action: .notForMe,
            operationId: "660e8400-e29b-41d4-a716-446655440000"
        )
        let second = canonicalCommand(
            action: .liked,
            operationId: "770e8400-e29b-41d4-a716-446655440000"
        )
        let client = TestAPIClient(shouldFail: false)
        client.canonicalResponses = [
            canonicalResponse(
                command: first,
                version: "6",
                profileSummary: "First N+1",
                primaryGameId: "celeste"
            ),
            canonicalResponse(
                command: CanonicalDecisionCommand(
                    operationId: second.operationId,
                    expectedStateVersion: "6",
                    actionType: second.actionType,
                    gameId: second.gameId
                ),
                version: "7",
                profileSummary: "Second N+2",
                primaryGameId: "ori"
            ),
        ]
        let viewModel = PlayViewModel(apiClient: client)
        viewModel.stateVersion = "5"
        LocalStorageService.shared.enqueueCanonicalDecision(first)
        LocalStorageService.shared.enqueueCanonicalDecision(second)

        await viewModel.drainCanonicalDecisions()

        XCTAssertEqual(client.submittedCommands.map(\.operationId), [first.operationId, second.operationId])
        XCTAssertEqual(client.submittedCommands.map(\.expectedStateVersion), ["5", "6"])
        XCTAssertEqual(client.maximumConcurrentSubmits, 1)
        XCTAssertEqual(viewModel.stateVersion, "7")
        XCTAssertTrue(LocalStorageService.shared.loadCanonicalDecisions().isEmpty)
    }
}

private final class TestAPIClient: PlayfitAPIClient, @unchecked Sendable {
    let shouldFail: Bool
    var savedStates: [String: UserGameState] = [:]
    var playNextResult = PlayNextModel()
    var picksResult: [RankedRecommendation] = []
    var profileResult: UserProfile?
    var gameStatesResult: [String: UserGameState] = [:]
    var platformsResult: [Platform] = []
    var needsResyncOnce = false
    var playNextCallCount = 0
    var saveProfileCallCount = 0
    var canonicalResponses: [CanonicalDecisionResponse] = []
    var submittedCommands: [CanonicalDecisionCommand] = []
    var authoritativeSnapshotResult: AuthoritativeSnapshot?
    var conflictOnNextSubmit = false
    var submitFailuresRemaining = 0
    var concurrentSubmits = 0
    var maximumConcurrentSubmits = 0

    init(shouldFail: Bool) {
        self.shouldFail = shouldFail
    }

    func fetchPlayNext() async throws -> PlayNextModel {
        if shouldFail { throw TestAPIError.failed }
        playNextCallCount += 1
        if needsResyncOnce {
            needsResyncOnce = false
            throw APIError.server(200, "needsResync")
        }
        return playNextResult
    }
    func fetchAuthoritativeSnapshot() async throws -> AuthoritativeSnapshot {
        if let authoritativeSnapshotResult { return authoritativeSnapshotResult }
        let model = try await fetchPlayNext()
        return AuthoritativeSnapshot(
            stateVersion: model.stateVersion.isEmpty ? "0" : model.stateVersion,
            profile: profileResult ?? UserProfile(),
            gameStates: gameStatesResult,
            recommendationModel: model,
            onboarding: CanonicalOnboardingState(
                step: "dislikes",
                platforms: [],
                likedGameIds: [],
                dislikedGameIds: []
            ),
            onboardingCompletedAt: "2026-01-01T00:00:00Z",
            lastUpdatedAt: "2026-01-01T00:00:00Z"
        )
    }
    func submitCanonicalDecision(
        _ command: CanonicalDecisionCommand
    ) async throws -> CanonicalDecisionResponse {
        submittedCommands.append(command)
        concurrentSubmits += 1
        maximumConcurrentSubmits = max(maximumConcurrentSubmits, concurrentSubmits)
        defer { concurrentSubmits -= 1 }
        if conflictOnNextSubmit {
            conflictOnNextSubmit = false
            throw APIError.canonicalConflict(currentStateVersion: "7", undoUnavailable: false)
        }
        if submitFailuresRemaining > 0 {
            submitFailuresRemaining -= 1
            throw TestAPIError.failed
        }
        guard !canonicalResponses.isEmpty else { throw TestAPIError.failed }
        return canonicalResponses.removeFirst()
    }
    func fetchPicks() async throws -> [RankedRecommendation] {
        if shouldFail { throw TestAPIError.failed }
        return picksResult
    }
    func fetchProfile() async throws -> UserProfile? {
        if shouldFail { throw TestAPIError.failed }
        return profileResult
    }
    func fetchGameStates() async throws -> [String: UserGameState] {
        if shouldFail { throw TestAPIError.failed }
        return gameStatesResult
    }
    func fetchOnboardingCompletedAt() async throws -> String? { nil }
    func searchGames(query: String) async throws -> [Game] { [] }
    func fetchGame(gameId: String) async throws -> Game? { nil }

    func saveGameState(gameId: String, state: UserGameState) async throws {
        if shouldFail { throw TestAPIError.failed }
        savedStates[gameId] = state
    }

    func saveProfile(
        profile: UserProfile,
        gameStates: [String: UserGameState],
        onboarding: OnboardingPayload,
        stateVersion: String
    ) async throws -> String {
        if shouldFail { throw TestAPIError.failed }
        saveProfileCallCount += 1
        return stateVersion == "0" ? "1" : stateVersion
    }

    func fetchPlatforms() async throws -> [Platform] {
        if shouldFail { throw TestAPIError.failed }
        return platformsResult
    }
    func fetchGamesBatch(gameIds: [String]) async throws -> [Game] { [] }
    func deleteProfile() async throws {
        if shouldFail { throw TestAPIError.failed }
    }

    func deleteGameState(gameId: String) async throws {
        if shouldFail { throw TestAPIError.failed }
        savedStates.removeValue(forKey: gameId)
    }

    func setAuthSession(_ session: AuthSession?) {}
}

private enum TestAPIError: Error {
    case failed
}

private func canonicalCommand(
    action: CanonicalDecisionActionType,
    operationId: String = "660e8400-e29b-41d4-a716-446655440000"
) -> CanonicalDecisionCommand {
    CanonicalDecisionCommand(
        operationId: operationId,
        expectedStateVersion: "5",
        actionType: action,
        gameId: "hades",
        played: action == .loved || action == .liked ? true : nil
    )
}

private func canonicalResponse(
    command: CanonicalDecisionCommand,
    version: String,
    profileSummary: String,
    primaryGameId: String,
    gameState: UserGameState? = UserGameState(rating: 5, updatedAt: "2026-01-02T00:00:00Z"),
    undoTargetOperationId: String? = nil
) -> CanonicalDecisionResponse {
    let profile = UserProfile(summary: profileSummary, likedGenres: ["Action"], ratedCount: 3)
    let onboarding = CanonicalOnboardingState(
        step: "dislikes",
        platforms: [CanonicalPlatformSelection(platformId: "switch", status: "available")],
        likedGameIds: ["celeste"],
        dislikedGameIds: []
    )
    let states = gameState.map { ["hades": $0] } ?? [:]
    let recommendation = RankedRecommendation(
        game: Game(id: primaryGameId, title: primaryGameId.capitalized),
        affinityScore: 92,
        riskScore: 5,
        confidence: .high
    )
    let model = PlayNextModel(
        primary: recommendation,
        stateVersion: version,
        rankingMetadata: RankingMetadata(
            profileStateVersion: version,
            candidates: [RankingCandidate(gameId: primaryGameId, rank: 1)]
        )
    )
    return CanonicalDecisionResponse(
        operationId: command.operationId,
        stateVersion: version,
        state: CanonicalProductState(
            version: 2,
            stateVersion: version,
            user: CanonicalUserState(
                onboarding: onboarding,
                onboardingCompletedAt: "2026-01-01T00:00:00Z",
                profile: profile,
                gameStates: states,
                lastUpdatedAt: "2026-01-02T00:00:00Z"
            )
        ),
        gameState: gameState,
        profile: CanonicalVersionedProfile(profile: profile, stateVersion: version),
        recommendationModel: model,
        undo: undoTargetOperationId.map {
            CanonicalUndoMetadata(
                targetOperationId: $0,
                gameId: "hades",
                restoredPreviousState: false
            )
        }
    )
}

private func authoritativeSnapshot(
    version: String,
    profileSummary: String,
    primaryGameId: String
) -> AuthoritativeSnapshot {
    let profile = UserProfile(summary: profileSummary, ratedCount: 2)
    let recommendation = RankedRecommendation(
        game: Game(id: primaryGameId, title: primaryGameId.capitalized),
        affinityScore: 90,
        riskScore: 4,
        confidence: .high
    )
    return AuthoritativeSnapshot(
        stateVersion: version,
        profile: profile,
        gameStates: [:],
        recommendationModel: PlayNextModel(
            primary: recommendation,
            stateVersion: version,
            rankingMetadata: RankingMetadata(
                profileStateVersion: version,
                candidates: [RankingCandidate(gameId: primaryGameId, rank: 1)]
            )
        ),
        onboarding: CanonicalOnboardingState(
            step: "dislikes",
            platforms: [],
            likedGameIds: [],
            dislikedGameIds: []
        ),
        onboardingCompletedAt: "2026-01-01T00:00:00Z",
        lastUpdatedAt: "2026-01-01T00:00:00Z"
    )
}
