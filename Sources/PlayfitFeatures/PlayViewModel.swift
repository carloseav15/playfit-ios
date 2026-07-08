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

@Observable
@MainActor
public final class PlayViewModel {
    public var pool: [RankedRecommendation]
    public var pickRecommendations: [RankedRecommendation]
    public var stablePrimaryId: String?
    public var excludedIds: Set<String>
    public var gameStates: [String: UserGameState]
    public var profile: UserProfile
    public internal(set) var pickIds: Set<String>
    public internal(set) var isLoading: Bool
    public internal(set) var error: String?
    public internal(set) var syncState: PlayfitSyncState
    public internal(set) var lastSyncedAt: Date?
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
    public internal(set) var authSession: AuthSession? {
        didSet { apiClient?.setAuthSession(authSession) }
    }
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
        storage.loadPendingActions().count
    }
}
