import Foundation
import Logging
import PlayfitModels
import SwiftData

public final class LocalStorageService: Sendable {
    public static let shared = LocalStorageService()

    private let container: ModelContainer
    private let logger = Logger(label: "com.playfit.storage")

    public init() {
        do {
            let schema = Schema([SDProfile.self, SDGameState.self, SDCachedRecommendation.self, SDPendingAction.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            logger.error("ModelContainer setup failed: \(error.localizedDescription)")
            fatalError("PlayfitStorage: could not initialize ModelContainer: \(error)")
        }
    }

    // MARK: - Context

    private func newContext() -> ModelContext {
        ModelContext(container)
    }

    // MARK: - Profile

    public func loadProfile() -> UserProfile? {
        let context = newContext()
        let descriptor = FetchDescriptor<SDProfile>()
        guard let sd = try? context.fetch(descriptor).first else { return nil }
        return UserProfile(
            summary: sd.summary,
            likedGenres: sd.likedGenres,
            avoidedGenres: sd.avoidedGenres,
            likedTags: sd.likedTags,
            dislikedTags: sd.dislikedTags,
            ratedCount: sd.ratedCount,
            signals: []
        )
    }

    public func loadOnboardingStatus() -> (completed: Bool, platformIds: Set<String>) {
        let context = newContext()
        let descriptor = FetchDescriptor<SDProfile>()
        guard let sd = try? context.fetch(descriptor).first else {
            return (false, [])
        }
        return (sd.onboardingCompleted, Set(sd.selectedPlatformIds))
    }

    public func saveProfile(_ profile: UserProfile, platformIds: Set<String>, onboardingCompleted: Bool) {
        let context = newContext()
        let descriptor = FetchDescriptor<SDProfile>()
        let existing = try? context.fetch(descriptor).first
        let sd = existing ?? SDProfile()
        sd.summary = profile.summary
        sd.likedGenres = profile.likedGenres
        sd.avoidedGenres = profile.avoidedGenres
        sd.likedTags = profile.likedTags
        sd.dislikedTags = profile.dislikedTags
        sd.ratedCount = profile.ratedCount
        sd.selectedPlatformIds = Array(platformIds)
        sd.onboardingCompleted = onboardingCompleted
        if existing == nil { context.insert(sd) }
        try? context.save()
    }

    public func saveOnboardingMetadata(likedIds: [String], dislikedIds: [String], completedAt: String?) {
        UserDefaults.standard.set(likedIds, forKey: "playfit.onboarding.likedIds")
        UserDefaults.standard.set(dislikedIds, forKey: "playfit.onboarding.dislikedIds")
        UserDefaults.standard.set(completedAt, forKey: "playfit.onboarding.completedAt")
    }

    public func loadOnboardingMetadata() -> (likedIds: [String], dislikedIds: [String], completedAt: String?) {
        let likedIds = UserDefaults.standard.stringArray(forKey: "playfit.onboarding.likedIds") ?? []
        let dislikedIds = UserDefaults.standard.stringArray(forKey: "playfit.onboarding.dislikedIds") ?? []
        let completedAt = UserDefaults.standard.string(forKey: "playfit.onboarding.completedAt")
        return (likedIds, dislikedIds, completedAt)
    }

    // MARK: - Game States

    public func loadGameStates() -> [String: UserGameState] {
        let context = newContext()
        let descriptor = FetchDescriptor<SDGameState>()
        guard let results = try? context.fetch(descriptor) else { return [:] }
        var states: [String: UserGameState] = [:]
        for sd in results {
            let status: PlayStatus? = sd.status.flatMap { PlayStatus(rawValue: $0) }
            states[sd.gameId] = UserGameState(
                status: status,
                rating: sd.rating,
                inPlayfitPicks: sd.inPlayfitPicks,
                excluded: sd.excluded,
                updatedAt: sd.updatedAt
            )
        }
        return states
    }

    public func deleteGameState(gameId: String) {
        let context = newContext()
        let id = gameId
        let descriptor = FetchDescriptor<SDGameState>(predicate: #Predicate { $0.gameId == id })
        guard let existing = try? context.fetch(descriptor).first else { return }
        context.delete(existing)
        try? context.save()
    }

    public func saveGameState(gameId: String, state: UserGameState) {
        let context = newContext()
        let id = gameId
        let descriptor = FetchDescriptor<SDGameState>(predicate: #Predicate { $0.gameId == id })
        let existing = try? context.fetch(descriptor).first
        let sd = existing ?? SDGameState(gameId: gameId)
        sd.status = state.status?.rawValue
        sd.rating = state.rating
        sd.inPlayfitPicks = state.inPlayfitPicks
        sd.excluded = state.excluded
        sd.updatedAt = state.updatedAt
        if existing == nil { context.insert(sd) }
        try? context.save()
    }

    // MARK: - Cached Recommendations

    public func loadCachedRecommendations() -> [RankedRecommendation] {
        let context = newContext()
        let descriptor = FetchDescriptor<SDCachedRecommendation>()
        guard let results = try? context.fetch(descriptor) else { return [] }
        var recs: [RankedRecommendation] = []
        for sd in results {
            if let rec = try? JSONDecoder().decode(RankedRecommendation.self, from: sd.rankJSON) {
                recs.append(rec)
            }
        }
        return recs
    }

    public func cacheRecommendations(_ recommendations: [RankedRecommendation]) {
        let context = newContext()
        for rec in recommendations {
            guard let data = try? JSONEncoder().encode(rec) else { continue }
            let id = rec.game.id
            let descriptor = FetchDescriptor<SDCachedRecommendation>(predicate: #Predicate { $0.gameId == id })
            let existing = try? context.fetch(descriptor).first
            let sd = existing ?? SDCachedRecommendation(gameId: id, rankJSON: data)
            sd.rankJSON = data
            sd.cachedAt = Date()
            if existing == nil { context.insert(sd) }
        }
        try? context.save()
    }

    // MARK: - Pending Actions

    public func enqueuePendingAction(gameId: String, actionType: String, payload: Data) {
        let context = newContext()
        let descriptor = FetchDescriptor<SDPendingAction>(
            predicate: #Predicate { $0.gameId == gameId && $0.actionType == actionType }
        )
        let existing = try? context.fetch(descriptor).first
        let sd = existing ?? SDPendingAction(gameId: gameId, actionType: actionType, payload: payload)
        sd.payload = payload
        sd.createdAt = Date()
        sd.retryCount = 0
        if existing == nil { context.insert(sd) }
        try? context.save()
    }

    public func loadPendingActions() -> [SDPendingAction] {
        let context = newContext()
        var descriptor = FetchDescriptor<SDPendingAction>()
        descriptor.sortBy = [SortDescriptor(\.createdAt, order: .forward)]
        return (try? context.fetch(descriptor)) ?? []
    }

    public func removePendingAction(id: String) {
        let context = newContext()
        let descriptor = FetchDescriptor<SDPendingAction>(predicate: #Predicate { $0.id == id })
        guard let existing = try? context.fetch(descriptor).first else { return }
        context.delete(existing)
        try? context.save()
    }

    public func removePendingAction(gameId: String, actionType: String) {
        let context = newContext()
        let descriptor = FetchDescriptor<SDPendingAction>(
            predicate: #Predicate { $0.gameId == gameId && $0.actionType == actionType }
        )
        guard let existing = try? context.fetch(descriptor).first else { return }
        context.delete(existing)
        try? context.save()
    }

    // MARK: - Full Wipe

    public func deleteAllLocalData() {
        let context = newContext()
        if let profiles = try? context.fetch(FetchDescriptor<SDProfile>()) {
            for sd in profiles { context.delete(sd) }
        }
        if let states = try? context.fetch(FetchDescriptor<SDGameState>()) {
            for sd in states { context.delete(sd) }
        }
        if let recs = try? context.fetch(FetchDescriptor<SDCachedRecommendation>()) {
            for sd in recs { context.delete(sd) }
        }
        if let pending = try? context.fetch(FetchDescriptor<SDPendingAction>()) {
            for sd in pending { context.delete(sd) }
        }
        try? context.save()
        UserDefaults.standard.removeObject(forKey: "playfit.onboarding.likedIds")
        UserDefaults.standard.removeObject(forKey: "playfit.onboarding.dislikedIds")
        UserDefaults.standard.removeObject(forKey: "playfit.onboarding.completedAt")
    }
}
