import PlayfitAPI
import PlayfitDesignSystem
import PlayfitLogic
import PlayfitModels
import PlayfitStorage
import SwiftUI

public enum PlayfitSyncState: Equatable, Sendable {
    case idle
    case syncing
    case synced
    case failed
    case offline
}

@Observable
@MainActor
public final class PlayViewModel {
    public var pool: [RankedRecommendation]
    public var pickRecommendations: [RankedRecommendation]
    public var stablePrimaryId: String?
    public var excludedIds: Set<String>
    public var gameStates: [String: UserGameState]
    public var profile: UserProfile
    public private(set) var pickIds: Set<String>
    public private(set) var isLoading: Bool
    public private(set) var error: String?
    public private(set) var syncState: PlayfitSyncState
    public private(set) var lastSyncedAt: Date?
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
        self.pickRecommendations = recommendations.filter(\.inPlayfitPicks)
        self.excludedIds = []
        self.gameStates = [:]
        self.profile = profile
        self.pickIds = Set(recommendations.filter(\.inPlayfitPicks).map(\.game.id))
        self.isLoading = false
        self.syncState = apiClient == nil ? .offline : .idle
        self.lastSyncedAt = nil
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
            pickIds = activePickIds(in: gameStates)
            pickRecommendations = cached.filter { pickIds.contains($0.game.id) }
            pool = cached.filter { !pickIds.contains($0.game.id) }
            stablePrimaryId = pool.first?.game.id
        } else if onboardingCompleted {
            isLoading = true
            error = "No cached recommendations available. Connect to sync."
        }
    }

    @MainActor
    public func syncIfOnline() async {
        guard let apiClient else {
            syncState = .offline
            return
        }
        isLoading = true
        syncState = .syncing
        error = nil
        do {
            // Upload anything still pending (ratings, picks, etc.) before asking the
            // server for fresh recommendations — otherwise the server can hand back a
            // candidate the user just rated or picked locally, because it hasn't seen
            // that change yet.
            await drainPendingActions()

            let playNextResult: PlayNextModel
            do {
                playNextResult = try await apiClient.fetchPlayNext()
            } catch APIError.server(200, _) {
                // Server returned needsResync — upload our local profile first
                try await syncProfileToServer()
                playNextResult = try await apiClient.fetchPlayNext()
            }

            async let profileData = apiClient.fetchProfile()
            async let gameStatesData = apiClient.fetchGameStates()
            async let picksData = apiClient.fetchPicks()

            let (profileResult, gameStatesResult, picksResult) = try await (
                profileData,
                gameStatesData,
                picksData
            )

            // Platforms are treated as best-effort, matching `load()`: a stale local
            // list shouldn't fail the whole sync when this endpoint has a problem.
            if let platformsResult = try? await apiClient.fetchPlatforms(), !platformsResult.isEmpty {
                self.platforms = platformsResult
            }

            self.pool = ([playNextResult.primary].compactMap { $0 } + playNextResult.alternatives)
            self.gameStates = overlayStillPending(on: gameStatesResult)
            self.pickRecommendations = picksResult
            if let profile = profileResult {
                self.profile = profile
            }
            self.pickIds = activePickIds(in: self.gameStates)
            self.stablePrimaryId = playNextResult.primary?.game.id
            self.excludedIds = []

            storage.cacheRecommendations(uniqueRecommendations(self.pool + self.pickRecommendations))
            storage.saveProfile(self.profile, platformIds: self.selectedPlatformIds, onboardingCompleted: self.onboardingCompleted)
            for (gameId, state) in self.gameStates {
                storage.saveGameState(gameId: gameId, state: state)
            }
            self.lastSyncedAt = Date()
            self.syncState = .synced
        } catch {
            self.error = error.localizedDescription
            self.syncState = .failed
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
        guard let apiClient else {
            syncState = .offline
            return
        }
        isLoading = true
        syncState = .syncing
        error = nil
        do {
            async let playNextData = apiClient.fetchPlayNext()
            async let picksData = apiClient.fetchPicks()
            let (playNext, picksResult) = try await (playNextData, picksData)
            let existingIds = Set(pool.map(\.game.id))
            let fresh = ([playNext.primary].compactMap { $0 } + playNext.alternatives)
                .filter { !excludedIds.contains($0.game.id) || !existingIds.contains($0.game.id) }
            self.pool = fresh
            self.pickRecommendations = picksResult
            self.pickIds = activePickIds(in: gameStates)
            self.stablePrimaryId = playNext.primary?.game.id

            storage.cacheRecommendations(uniqueRecommendations(fresh + picksResult))
            self.lastSyncedAt = Date()
            self.syncState = .synced
        } catch {
            self.error = error.localizedDescription
            self.syncState = .failed
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
        uniqueRecommendations(pickRecommendations + pool)
            .filter { pickIds.contains($0.game.id) }
            .sorted { $0.affinityScore > $1.affinityScore }
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
        guard pickIds.count < 100 else {
            showToast("Picks is limited to 100 games", style: .error)
            return
        }
        let state = gameStates[entry.game.id]
        guard state?.excluded != true,
              state?.status.map({ !isTerminal($0) }) ?? true else {
            showToast("Finished or excluded games cannot be added to Picks", style: .error)
            return
        }
        advancePast(entry.game.id)
        pickIds.insert(entry.game.id)
        gamesCache[entry.game.id] = entry.game
        setPlayfitPick(gameStates: &gameStates, gameId: entry.game.id, picked: true)
        var savedEntry = entry
        savedEntry.inPlayfitPicks = true
        pickRecommendations.removeAll { $0.game.id == entry.game.id }
        pickRecommendations.insert(savedEntry, at: 0)
        persistGameState(gameId: entry.game.id)
        storage.cacheRecommendations(uniqueRecommendations(pool + pickRecommendations))
        showToast("Saved to Picks")
    }

    public func notForMe(_ entry: RankedRecommendation) {
        advancePast(entry.game.id)
        gamesCache[entry.game.id] = entry.game
        pickIds.remove(entry.game.id)
        pickRecommendations.removeAll { $0.game.id == entry.game.id }
        applyDecisionFeedback(gameStates: &gameStates, gameId: entry.game.id, feedback: .notForMe)
        persistGameState(gameId: entry.game.id)
        rebuildProfileFromCurrentSignals()
        showToast("Skipped")
    }

    public func alreadyPlayed(_ entry: RankedRecommendation, feedback: AlreadyPlayedFeedback) {
        advancePast(entry.game.id)
        gamesCache[entry.game.id] = entry.game
        pickIds.remove(entry.game.id)
        pickRecommendations.removeAll { $0.game.id == entry.game.id }
        applyDecisionFeedback(gameStates: &gameStates, gameId: entry.game.id, feedback: feedback)
        persistGameState(gameId: entry.game.id)
        rebuildProfileFromCurrentSignals()
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

    public func clearError() {
        error = nil
        if syncState == .failed { syncState = .idle }
    }

    @MainActor
    public func resetAllLocalState() {
        pool = []
        pickRecommendations = []
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
        syncState = apiClient == nil ? .offline : .idle
        lastSyncedAt = nil
        authSession = nil
        AuthSessionStore.clear()
    }

    public func removePick(_ gameId: String) {
        pickIds.remove(gameId)
        pickRecommendations.removeAll { $0.game.id == gameId }
        setPlayfitPick(gameStates: &gameStates, gameId: gameId, picked: false)
        persistGameState(gameId: gameId)
        storage.cacheRecommendations(uniqueRecommendations(pool + pickRecommendations))
        showToast("Removed from Picks")
    }

    public func deleteSignal(_ gameId: String, source: String) {
        if source == "onboarding_liked" {
            onboardingLikedGameIds.removeAll { $0 == gameId }
        } else if source == "onboarding_disliked" {
            onboardingDislikedGameIds.removeAll { $0 == gameId }
        } else if var state = gameStates[gameId] {
            state.rating = nil
            state.excluded = false
            if let status = state.status, isTerminal(status) {
                state.status = nil
            }
            if state.inPlayfitPicks || state.inBacklog || state.inWishlist {
                gameStates[gameId] = state
                persistGameState(gameId: gameId)
            } else {
                gameStates.removeValue(forKey: gameId)
                storage.deleteGameState(gameId: gameId)
                deleteGameStateOrQueue(gameId: gameId)
            }
        }
        if source != "rating",
           let state = gameStates[gameId],
           state.source == "onboarding",
           state.rating == nil,
           state.status == nil,
           !state.inPlayfitPicks,
           !state.inBacklog,
           !state.inWishlist,
           !state.excluded {
            gameStates.removeValue(forKey: gameId)
            storage.deleteGameState(gameId: gameId)
            deleteGameStateOrQueue(gameId: gameId)
        }
        storage.saveOnboardingMetadata(
            likedIds: onboardingLikedGameIds,
            dislikedIds: onboardingDislikedGameIds,
            completedAt: onboardingCompletedAt
        )
        rebuildProfileFromCurrentSignals()
        showToast("Signal deleted")
    }

    public func updateSignal(gameId: String, feedback: String) {
        guard let decision = DecisionFeedback(rawValue: feedback) else { return }
        applyDecisionFeedback(gameStates: &gameStates, gameId: gameId, feedback: decision)
        if gameStates[gameId]?.inPlayfitPicks != true {
            pickIds.remove(gameId)
            pickRecommendations.removeAll { $0.game.id == gameId }
        }
        persistGameState(gameId: gameId)
        rebuildProfileFromCurrentSignals()
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
        await adoptServerAccountState()
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
        await adoptServerAccountState()
        showToast("Account created", style: .success)
        return true
    }

    @MainActor
    public func resetPassword(email: String) async throws {
        let client = SupabaseAuthClient()
        try await client.resetPasswordForEmail(email)
    }

    @MainActor
    public func signInWithGoogle() async throws {
        let client = SupabaseAuthClient()
        let newSession = try await client.signInWithGoogle()
        authSession = newSession
        AuthSessionStore.save(newSession)
        await adoptServerAccountState()
        showToast("Signed in with Google", style: .success)
    }

    /// Pushes any local profile up (triggering the server-side anonymous-device
    /// migration if this account had none), then pulls the account's real state
    /// back down — including onboarding completion, which a plain push never sets.
    @MainActor
    private func adoptServerAccountState() async {
        try? await syncProfileToServer()
        await syncIfOnline()
        guard let apiClient,
              let completedAt = try? await apiClient.fetchOnboardingCompletedAt() else { return }
        onboardingCompleted = true
        onboardingCompletedAt = completedAt
        storage.saveProfile(profile, platformIds: selectedPlatformIds, onboardingCompleted: true)
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
    public func deleteCloudProfile() async throws {
        guard let apiClient else { throw APIError.unexpectedResponse }
        try await apiClient.deleteProfile()
        if let token = authSession?.accessToken {
            await SupabaseAuthClient().signOut(accessToken: token)
        }
        storage.deleteAllLocalData()
        resetAllLocalState()
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
        for rec in pool + pickRecommendations {
            gamesCache[rec.game.id] = rec.game
        }
        
        let statesIds = gameStates.keys
        let signalIds = profile.signals.map { $0.id }
        let allNeededIds = Array(
            Set(statesIds)
                .union(signalIds)
                .union(onboardingLikedGameIds)
                .union(onboardingDislikedGameIds)
        )
        
        let missingIds = allNeededIds.filter { gamesCache[$0] == nil }
        guard !missingIds.isEmpty else {
            rebuildProfileFromCurrentSignals()
            return
        }
        guard let apiClient else {
            rebuildProfileFromCurrentSignals()
            return
        }
        
        isLoading = true
        do {
            let fetchedGames = try await apiClient.fetchGamesBatch(gameIds: missingIds)
            for game in fetchedGames {
                gamesCache[game.id] = game
            }
            rebuildProfileFromCurrentSignals()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func isTerminal(_ status: PlayStatus) -> Bool {
        [.completed, .beaten, .abandoned, .dropped].contains(status)
    }

    private func activePickIds(in states: [String: UserGameState]) -> Set<String> {
        Set(states.compactMap { gameId, state in
            guard state.inPlayfitPicks,
                  !state.excluded,
                  state.status.map({ !isTerminal($0) }) ?? true else { return nil }
            return gameId
        })
    }

    private func uniqueRecommendations(_ recommendations: [RankedRecommendation]) -> [RankedRecommendation] {
        var seen = Set<String>()
        return recommendations.filter { seen.insert($0.game.id).inserted }
    }

    private func rebuildProfileFromCurrentSignals() {
        profile = rebuildUserProfile(
            onboardingLikedIds: onboardingLikedGameIds,
            onboardingDislikedIds: onboardingDislikedGameIds,
            gameStates: gameStates,
            gamesCache: gamesCache
        )
        storage.saveProfile(profile, platformIds: selectedPlatformIds, onboardingCompleted: onboardingCompleted)
    }
}

// MARK: - Environment

private struct PlayViewModelKey: EnvironmentKey {
    static var defaultValue: PlayViewModel {
        MainActor.assumeIsolated {
            PlayViewModel()
        }
    }
}

extension EnvironmentValues {
    @MainActor public var playViewModel: PlayViewModel {
        get { self[PlayViewModelKey.self] }
        set { self[PlayViewModelKey.self] = newValue }
    }
}
