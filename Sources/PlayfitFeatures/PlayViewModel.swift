import PlayfitAPI
import PlayfitDesignSystem
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

enum PendingDecisionUndo {
    case canonical(targetOperationId: String, gameId: String)
    case legacy(entry: RankedRecommendation, previousState: UserGameState?, wasPicked: Bool)
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
    public internal(set) var stateVersion: String
    public internal(set) var rankingMetadata: RankingMetadata
    public internal(set) var canonicalStatusMessage: String?
    public internal(set) var pickIds: Set<String>
    public internal(set) var isLoading: Bool
    public internal(set) var error: String?
    public internal(set) var syncState: PlayfitSyncState
    public internal(set) var lastSyncedAt: Date?
    public var toastMessage: String?
    public var toastStyle: ToastStyle = .success
    public var toastToken: Int = 0
    public var toastActionTitle: String?
    public var toastAction: (() -> Void)?
    var pendingUndo: PendingDecisionUndo?
    var canonicalDrainInProgress = false
    var hasAuthoritativeSnapshot = false
    public var onboardingStarted: Bool
    public var onboardingCompleted: Bool
    public var selectedPlatformIds: Set<String>
    public var onboardingLikedGameIds: [String] = []
    public var onboardingDislikedGameIds: [String] = []
    public var onboardingCompletedAt: String?
    private var emittedCoreLoopObservationKeys: Set<String> = []

    public var platforms: [Platform]
    public var gamesCache: [String: Game] = [:]
    public var apiClient: PlayfitAPIClient? {
        didSet { apiClient?.setAuthSession(authSession) }
    }
    public internal(set) var authSession: AuthSession? {
        didSet { apiClient?.setAuthSession(authSession) }
    }
    /// Set when an incoming `playfit://auth-callback` deep link is a password-recovery
    /// link. Its session is not adopted as the active session until the user actually
    /// sets a new password, so the ResetPasswordView can be shown gating the rest of
    /// the app on the recovery flow completing.
    public internal(set) var pendingPasswordRecovery: AuthSession?
    let storage = LocalStorageService.shared

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
        self.stateVersion = "0"
        self.rankingMetadata = RankingMetadata(profileStateVersion: "0")
        self.canonicalStatusMessage = nil
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
        storage.loadPendingActions().count + storage.loadCanonicalDecisions().count
    }

    public func recordRecommendationObservation(_ eventName: String, entry: RankedRecommendation) {
        guard let rank = rankingMetadata.candidates.first(where: { $0.gameId == entry.game.id })?.rank else { return }
        let key = "\(eventName):\(stateVersion):\(entry.game.id):\(rank)"
        guard !emittedCoreLoopObservationKeys.contains(key) else { return }
        emittedCoreLoopObservationKeys.insert(key)
        let eventId = stableCoreLoopEventId(for: key)
        let event = CoreLoopClientEvent(
            eventId: eventId,
            eventName: eventName,
            recommendationId: "play-next:\(stateVersion)",
            stateVersion: stateVersion,
            gameId: entry.game.id,
            rank: rank
        )
        storage.enqueueTelemetryEvent(event)
        Task { await drainTelemetryEvents() }
    }

    private func stableCoreLoopEventId(for key: String) -> UUID {
        let defaultsKey = "playfit.core-loop.event.\(key)"
        if let raw = UserDefaults.standard.string(forKey: defaultsKey), let value = UUID(uuidString: raw) { return value }
        let value = UUID()
        UserDefaults.standard.set(value.uuidString, forKey: defaultsKey)
        return value
    }

    func drainTelemetryEvents() async {
        guard let apiClient else { return }
        for event in storage.loadTelemetryEvents() {
            do { try await apiClient.recordCoreLoopEvent(event); storage.removeTelemetryEvent(eventId: event.eventId) }
            catch { break }
        }
    }
}
