import PlayfitAPI
import PlayfitDesignSystem
import PlayfitLogic
import PlayfitModels
import PlayfitStorage
import SwiftUI

@Observable
public final class PlayViewModel: @unchecked Sendable {
    public var pool: [RankedRecommendation]
    public var stablePrimaryId: String?
    public var excludedIds: Set<String>
    public var gameStates: [String: UserGameState]
    public var profile: UserProfile
    public private(set) var pickIds: Set<String>
    public private(set) var isLoading: Bool
    public private(set) var error: String?
    public var toastMessage: String?
    public var toastStyle: ToastStyle = .success
    public var onboardingStarted: Bool
    public var onboardingCompleted: Bool
    public var selectedPlatformIds: Set<String>
    public var onboardingLikedGameIds: [String] = []
    public var onboardingDislikedGameIds: [String] = []
    public var onboardingCompletedAt: String?

    public var platforms: [Platform]
    public var gamesCache: [String: Game] = [:]
    public var apiClient: PlayfitAPIClient? {
        didSet { apiClient?.setAuthSession(authSession) }
    }
    public private(set) var authSession: AuthSession? {
        didSet { apiClient?.setAuthSession(authSession) }
    }
    private let storage = LocalStorageService.shared

    public static let fallbackPlatforms: [Platform] = [
        Platform(platformId: "switch_1", displayName: "Nintendo Switch", family: "nintendo", kind: "hybrid", sortOrder: 9),
        Platform(platformId: "switch_2", displayName: "Nintendo Switch 2", family: "nintendo", kind: "hybrid", sortOrder: 10),
        Platform(platformId: "ps5", displayName: "PlayStation 5", family: "playstation", kind: "console", sortOrder: 9),
        Platform(platformId: "ps4", displayName: "PlayStation 4", family: "playstation", kind: "console", sortOrder: 8),
        Platform(platformId: "xbox_series_xs", displayName: "Xbox Series X|S", family: "xbox", kind: "console", sortOrder: 9),
        Platform(platformId: "xbox_one", displayName: "Xbox One", family: "xbox", kind: "console", sortOrder: 8),
        Platform(platformId: "pc", displayName: "PC", family: "pc", kind: "computer", sortOrder: 10),
        Platform(platformId: "macos", displayName: "Mac", family: "pc", kind: "computer", sortOrder: 9),
        // Retro systems (similar to web)
        Platform(platformId: "snes", displayName: "Super Nintendo", family: "nintendo", kind: "console", sortOrder: 4),
        Platform(platformId: "n64", displayName: "Nintendo 64", family: "nintendo", kind: "console", sortOrder: 5),
        Platform(platformId: "wii", displayName: "Nintendo Wii", family: "nintendo", kind: "console", sortOrder: 7),
        Platform(platformId: "ps2", displayName: "PlayStation 2", family: "playstation", kind: "console", sortOrder: 6),
        Platform(platformId: "ps3", displayName: "PlayStation 3", family: "playstation", kind: "console", sortOrder: 7),
        Platform(platformId: "xbox_360", displayName: "Xbox 360", family: "xbox", kind: "console", sortOrder: 7)
    ]

    public init(
        recommendations: [RankedRecommendation] = [],
        profile: UserProfile = UserProfile(),
        apiClient: PlayfitAPIClient? = nil
    ) {
        self.pool = recommendations
        self.excludedIds = []
        self.gameStates = [:]
        self.profile = profile
        self.pickIds = Set(recommendations.filter(\.inPlayfitPicks).map(\.game.id))
        self.isLoading = false
        self.onboardingStarted = false
        self.onboardingCompleted = false
        self.selectedPlatformIds = []
        self.platforms = []
        self.apiClient = apiClient
        if let first = recommendations.first {
            self.stablePrimaryId = first.game.id
        }
    }

    // MARK: - Local-First Loading

    @MainActor
    public func loadLocal() {
        let status = storage.loadOnboardingStatus()
        onboardingCompleted = status.completed
        selectedPlatformIds = status.platformIds
        platforms = Self.fallbackPlatforms

        if let localProfile = storage.loadProfile() {
            profile = localProfile
        }

        let meta = storage.loadOnboardingMetadata()
        self.onboardingLikedGameIds = meta.likedIds
        self.onboardingDislikedGameIds = meta.dislikedIds
        self.onboardingCompletedAt = meta.completedAt

        // Auto-heal missing onboarding metadata if onboarding was already completed
        if onboardingCompleted && onboardingCompletedAt == nil {
            let now = ISO8601DateFormatter().string(from: Date())
            self.onboardingCompletedAt = now
            // Deduce liked IDs from game states if empty
            let states = storage.loadGameStates()
            let likedFromStates = states.filter { $0.value.rating == 5.0 }.map { $0.key }
            let avoidedFromStates = states.filter { $0.value.excluded }.map { $0.key }
            self.onboardingLikedGameIds = likedFromStates.isEmpty ? ["celeste"] : likedFromStates // Celeste is our standard fallback
            self.onboardingDislikedGameIds = avoidedFromStates
            storage.saveOnboardingMetadata(likedIds: onboardingLikedGameIds, dislikedIds: onboardingDislikedGameIds, completedAt: now)
        }

        authSession = AuthSessionStore.load()
        gameStates = storage.loadGameStates()
        let cached = storage.loadCachedRecommendations()
        if !cached.isEmpty {
            pool = cached
            pickIds = Set(cached.filter(\.inPlayfitPicks).map(\.game.id))
            stablePrimaryId = cached.first?.game.id
        } else if onboardingCompleted {
            isLoading = true
            error = "No cached recommendations available. Connect to sync."
        }
    }

    @MainActor
    public func syncIfOnline() async {
        guard let apiClient else { return }
        isLoading = true
        error = nil
        do {
            let playNextResult: PlayNextModel
            do {
                playNextResult = try await apiClient.fetchPlayNext()
            } catch APIError.server(200, _) {
                // Server returned needsResync — upload our local profile first
                try await syncProfileToServer()
                playNextResult = try await apiClient.fetchPlayNext()
            }

            await drainPendingActions()

            async let profileData = apiClient.fetchProfile()
            async let gameStatesData = apiClient.fetchGameStates()
            async let platformsData = apiClient.fetchPlatforms()

            let (profileResult, gameStatesResult, platformsResult) = try await (profileData, gameStatesData, platformsData)

            self.pool = ([playNextResult.primary].compactMap { $0 } + playNextResult.alternatives)
            self.gameStates = overlayStillPending(on: gameStatesResult)
            if let profile = profileResult {
                self.profile = profile
            }
            if !platformsResult.isEmpty {
                self.platforms = platformsResult
            }
            self.pickIds = Set(playNextResult.savedPickIds)
            self.stablePrimaryId = playNextResult.primary?.game.id
            self.excludedIds = []

            storage.cacheRecommendations(self.pool)
            storage.saveProfile(self.profile, platformIds: self.selectedPlatformIds, onboardingCompleted: self.onboardingCompleted)
            for (gameId, state) in self.gameStates {
                storage.saveGameState(gameId: gameId, state: state)
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    public func buildOnboardingPayload() -> OnboardingPayload {
        OnboardingPayload(
            step: onboardingCompleted ? "dislikes" : "platforms",
            platforms: Array(selectedPlatformIds),
            likedGameIds: onboardingLikedGameIds,
            dislikedGameIds: onboardingDislikedGameIds,
            onboardingCompletedAt: onboardingCompletedAt
        )
    }

    @MainActor
    public func syncProfileToServer() async throws {
        guard let apiClient else { return }
        try await apiClient.saveProfile(
            profile: profile,
            gameStates: gameStates,
            onboarding: buildOnboardingPayload()
        )
    }

    @MainActor
    public func load() async {
        loadLocal()
        if let apiClient {
            if let fetched = try? await apiClient.fetchPlatforms(), !fetched.isEmpty {
                self.platforms = fetched
            }
        }
        if onboardingCompleted {
            await syncIfOnline()
        }
    }

    public func refresh() async {
        guard let apiClient else { return }
        isLoading = true
        error = nil
        do {
            let playNext = try await apiClient.fetchPlayNext()
            let existingIds = Set(pool.map(\.game.id))
            let fresh = ([playNext.primary].compactMap { $0 } + playNext.alternatives)
                .filter { !excludedIds.contains($0.game.id) || !existingIds.contains($0.game.id) }
            self.pool = fresh
            self.pickIds = Set(playNext.savedPickIds)
            self.stablePrimaryId = playNext.primary?.game.id

            storage.cacheRecommendations(fresh)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Computed

    public var visiblePool: [RankedRecommendation] {
        pool.filter { !excludedIds.contains($0.game.id) }
    }

    public var primary: RankedRecommendation? {
        if let id = stablePrimaryId, let entry = visiblePool.first(where: { $0.game.id == id }) {
            return entry
        }
        return visiblePool.first
    }

    public var alternatives: [RankedRecommendation] {
        guard let primary else { return [] }
        guard let idx = visiblePool.firstIndex(where: { $0.game.id == primary.game.id }) else { return [] }
        return Array(visiblePool.dropFirst(idx + 1).prefix(3))
    }

    public var picks: [RankedRecommendation] {
        visiblePool.filter { pickIds.contains($0.game.id) }
    }

    public func isPicked(_ gameId: String) -> Bool {
        pickIds.contains(gameId)
    }

    public var pendingActionsCount: Int {
        storage.loadPendingActions().count
    }

    // MARK: - Actions

    private func advancePast(_ gameId: String) {
        excludedIds.insert(gameId)
        if stablePrimaryId == gameId {
            stablePrimaryId = visiblePool.first(where: { $0.game.id != gameId })?.game.id
        }
    }

    private func persistGameState(gameId: String) {
        guard let state = gameStates[gameId] else { return }
        storage.saveGameState(gameId: gameId, state: state)
        saveGameStateOrQueue(gameId: gameId, state: state)
    }

    public func addPick(_ entry: RankedRecommendation) {
        advancePast(entry.game.id)
        pickIds.insert(entry.game.id)
        applyDecisionFeedback(gameStates: &gameStates, gameId: entry.game.id, feedback: .liked)
        persistGameState(gameId: entry.game.id)
        showToast("Saved to Picks")
    }

    public func notForMe(_ entry: RankedRecommendation) {
        advancePast(entry.game.id)
        applyDecisionFeedback(gameStates: &gameStates, gameId: entry.game.id, feedback: .notForMe)
        persistGameState(gameId: entry.game.id)
        showToast("Skipped")
    }

    public func alreadyPlayed(_ entry: RankedRecommendation, feedback: AlreadyPlayedFeedback) {
        advancePast(entry.game.id)
        pickIds.remove(entry.game.id)
        applyDecisionFeedback(gameStates: &gameStates, gameId: entry.game.id, feedback: feedback)
        persistGameState(gameId: entry.game.id)
        showToast("Marked as played")
    }

    public func skip(_ entry: RankedRecommendation) {
        advancePast(entry.game.id)
        showToast("Skipped")
    }

    public func clearSkipped() {
        excludedIds = []
        showToast("Skipped games shown again")
    }

    @MainActor
    public func resetAllLocalState() {
        pool = []
        gameStates = [:]
        pickIds = []
        excludedIds = []
        stablePrimaryId = nil
        selectedPlatformIds = []
        onboardingStarted = false
        onboardingCompleted = false
        onboardingLikedGameIds = []
        onboardingDislikedGameIds = []
        onboardingCompletedAt = nil
        profile = UserProfile()
        error = nil
        authSession = nil
        AuthSessionStore.clear()
    }

    public func removePick(_ gameId: String) {
        pickIds.remove(gameId)
        gameStates[gameId]?.inPlayfitPicks = false
        persistGameState(gameId: gameId)
        showToast("Removed from Picks")
    }

    public func deleteSignal(_ gameId: String) {
        gameStates.removeValue(forKey: gameId)
        storage.deleteGameState(gameId: gameId)
        deleteGameStateOrQueue(gameId: gameId)
        showToast("Signal deleted")
    }

    public func updateSignal(gameId: String, feedback: String) {
        var state = gameStates[gameId] ?? UserGameState()
        switch feedback {
        case "played_loved":
            state.rating = 5.0
            state.excluded = false
        case "played_liked":
            state.rating = 4.0
            state.excluded = false
        case "played_mixed":
            state.rating = 3.0
            state.excluded = false
        case "played_dropped":
            state.rating = 2.0
            state.excluded = false
        case "not_for_me":
            state.rating = nil
            state.excluded = true
        default:
            break
        }
        gameStates[gameId] = state
        persistGameState(gameId: gameId)
        showToast("Signal updated")
    }

    // MARK: - Toast

    public func showToast(_ message: String, style: ToastStyle = .success) {
        toastMessage = message
        toastStyle = style
    }

    // MARK: - Authentication

    @MainActor
    public func signIn(email: String, password: String) async throws {
        let client = SupabaseAuthClient()
        let newSession = try await client.signIn(email: email, password: password)
        authSession = newSession
        AuthSessionStore.save(newSession)
        try? await syncProfileToServer()
        showToast("Signed in", style: .success)
    }

    /// Returns false when the account was created but needs email confirmation
    /// before a session exists (no session is issued yet in that case).
    @MainActor
    public func signUp(email: String, password: String) async throws -> Bool {
        let client = SupabaseAuthClient()
        guard let newSession = try await client.signUp(email: email, password: password) else {
            return false
        }
        authSession = newSession
        AuthSessionStore.save(newSession)
        try? await syncProfileToServer()
        showToast("Account created", style: .success)
        return true
    }

    @MainActor
    public func signInWithGoogle() async throws {
        let client = SupabaseAuthClient()
        let newSession = try await client.signInWithGoogle()
        authSession = newSession
        AuthSessionStore.save(newSession)
        try? await syncProfileToServer()
        showToast("Signed in with Google", style: .success)
    }

    @MainActor
    public func signOut() async {
        if let token = authSession?.accessToken {
            let client = SupabaseAuthClient()
            await client.signOut(accessToken: token)
        }
        authSession = nil
        AuthSessionStore.clear()
        showToast("Signed out", style: .success)
    }

    @MainActor
    public func forceSyncCloud() async {
        guard let apiClient else { return }
        isLoading = true
        error = nil
        do {
            try await apiClient.saveProfile(profile: self.profile, gameStates: self.gameStates, onboarding: buildOnboardingPayload())
            await syncIfOnline()
            showToast("Cloud sync completed", style: .success)
        } catch {
            self.error = error.localizedDescription
            showToast("Sync failed: \(error.localizedDescription)", style: .error)
        }
        isLoading = false
    }

    // MARK: - Sync

    private func saveGameStateOrQueue(gameId: String, state: UserGameState) {
        guard let apiClient else {
            queueSaveGameState(gameId: gameId, state: state)
            return
        }
        Task {
            do {
                try await apiClient.saveGameState(gameId: gameId, state: state)
                storage.removePendingAction(gameId: gameId, actionType: PendingActionType.saveGameState.rawValue)
            } catch {
                queueSaveGameState(gameId: gameId, state: state)
            }
        }
    }

    private func deleteGameStateOrQueue(gameId: String) {
        guard let apiClient else {
            storage.enqueuePendingAction(gameId: gameId, actionType: PendingActionType.deleteGameState.rawValue, payload: Data())
            return
        }
        Task {
            do {
                try await apiClient.deleteGameState(gameId: gameId)
                storage.removePendingAction(gameId: gameId, actionType: PendingActionType.deleteGameState.rawValue)
            } catch {
                storage.enqueuePendingAction(gameId: gameId, actionType: PendingActionType.deleteGameState.rawValue, payload: Data())
            }
        }
    }

    private func queueSaveGameState(gameId: String, state: UserGameState) {
        guard let payload = try? JSONEncoder().encode(state) else { return }
        storage.enqueuePendingAction(gameId: gameId, actionType: PendingActionType.saveGameState.rawValue, payload: payload)
    }

    /// Attempts to push every queued action to the server. Items that still fail
    /// (offline, server error) are left in the queue for the next sync attempt.
    private func drainPendingActions() async {
        guard let apiClient else { return }
        let pending = storage.loadPendingActions()
        for action in pending {
            guard let type = PendingActionType(rawValue: action.actionType) else { continue }
            do {
                switch type {
                case .saveGameState:
                    let state = try JSONDecoder().decode(UserGameState.self, from: action.payload)
                    try await apiClient.saveGameState(gameId: action.gameId, state: state)
                case .deleteGameState:
                    try await apiClient.deleteGameState(gameId: action.gameId)
                }
                storage.removePendingAction(id: action.id)
            } catch {
                // Leave queued; will be retried on the next syncIfOnline().
            }
        }
    }

    /// Re-applies any action still stuck in the queue on top of a freshly fetched
    /// server snapshot, so a pending local change is never visually undone.
    private func overlayStillPending(on serverGameStates: [String: UserGameState]) -> [String: UserGameState] {
        var merged = serverGameStates
        for action in storage.loadPendingActions() {
            guard let type = PendingActionType(rawValue: action.actionType) else { continue }
            switch type {
            case .saveGameState:
                if let state = try? JSONDecoder().decode(UserGameState.self, from: action.payload) {
                    merged[action.gameId] = state
                }
            case .deleteGameState:
                merged.removeValue(forKey: action.gameId)
            }
        }
        return merged
    }

    @MainActor
    public func hydrateTasteGames() async {
        // Hydrate from pool recommendations
        for rec in pool {
            gamesCache[rec.game.id] = rec.game
        }
        
        let statesIds = gameStates.keys
        let signalIds = profile.signals.map { $0.id }
        let allNeededIds = Array(Set(statesIds).union(signalIds))
        
        let missingIds = allNeededIds.filter { gamesCache[$0] == nil }
        guard !missingIds.isEmpty, let apiClient else { return }
        
        isLoading = true
        do {
            let fetchedGames = try await apiClient.fetchGamesBatch(gameIds: missingIds)
            for game in fetchedGames {
                gamesCache[game.id] = game
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Environment

private struct PlayViewModelKey: EnvironmentKey {
    static let defaultValue = PlayViewModel()
}

extension EnvironmentValues {
    public var playViewModel: PlayViewModel {
        get { self[PlayViewModelKey.self] }
        set { self[PlayViewModelKey.self] = newValue }
    }
}
