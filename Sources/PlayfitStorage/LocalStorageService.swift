import Foundation
import Logging
import PlayfitModels
import SwiftData

public final class LocalStorageService: Sendable {
    public static let shared = LocalStorageService()

    private let container: ModelContainer?
    private let logger = Logger(label: "com.playfit.storage")

    public init() {
        let schema = Schema([
            SDProfile.self,
            SDGameState.self,
            SDCachedRecommendation.self,
            SDPendingAction.self,
            SDAuthoritativeSnapshot.self,
            SDCanonicalOperation.self,
        ])
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            logger.error("Persistent ModelContainer setup failed: \(error.localizedDescription)")
            do {
                let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                container = try ModelContainer(for: schema, configurations: [fallbackConfig])
                logger.warning("Using an in-memory storage fallback; local data will not persist")
            } catch {
                logger.error("In-memory ModelContainer setup also failed: \(error.localizedDescription)")
                container = nil
            }
        }
    }

    public var isAvailable: Bool { container != nil }

    // MARK: - Context

    private func newContext() -> ModelContext? {
        guard let container else { return nil }
        return ModelContext(container)
    }

    // MARK: - Profile

    public func loadProfile() -> UserProfile? {
        guard let context = newContext() else { return nil }
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
        guard let context = newContext() else { return (false, []) }
        let descriptor = FetchDescriptor<SDProfile>()
        guard let sd = try? context.fetch(descriptor).first else {
            return (false, [])
        }
        return (sd.onboardingCompleted, Set(sd.selectedPlatformIds))
    }

    public func saveProfile(_ profile: UserProfile, platformIds: Set<String>, onboardingCompleted: Bool) {
        guard let context = newContext() else { return }
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
        guard let context = newContext() else { return [:] }
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
        guard let context = newContext() else { return }
        let id = gameId
        let descriptor = FetchDescriptor<SDGameState>(predicate: #Predicate { $0.gameId == id })
        guard let existing = try? context.fetch(descriptor).first else { return }
        context.delete(existing)
        try? context.save()
    }

    public func saveGameState(gameId: String, state: UserGameState) {
        guard let context = newContext() else { return }
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
        guard let context = newContext() else { return [] }
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
        guard let context = newContext() else { return }
        if let existing = try? context.fetch(FetchDescriptor<SDCachedRecommendation>()) {
            for cached in existing { context.delete(cached) }
        }
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

    // MARK: - Authoritative Snapshot

    public func loadAuthoritativeSnapshot() -> AuthoritativeSnapshot? {
        guard let context = newContext(),
              let stored = try? context.fetch(FetchDescriptor<SDAuthoritativeSnapshot>()).first else {
            return nil
        }
        return try? JSONDecoder().decode(AuthoritativeSnapshot.self, from: stored.snapshotData)
    }

    public func saveAuthoritativeSnapshot(_ snapshot: AuthoritativeSnapshot) {
        guard let context = newContext(),
              let data = try? JSONEncoder().encode(snapshot) else { return }
        let descriptor = FetchDescriptor<SDAuthoritativeSnapshot>()
        let existing = try? context.fetch(descriptor).first
        let stored = existing ?? SDAuthoritativeSnapshot(
            stateVersion: snapshot.stateVersion,
            snapshotData: data
        )
        stored.stateVersion = snapshot.stateVersion
        stored.snapshotData = data
        stored.updatedAt = Date()
        if existing == nil { context.insert(stored) }
        try? context.save()
    }

    // MARK: - Pending Canonical Decisions

    public func enqueueCanonicalDecision(_ command: CanonicalDecisionCommand) {
        guard let context = newContext() else { return }
        let operationId = command.operationId
        let descriptor = FetchDescriptor<SDCanonicalOperation>(
            predicate: #Predicate { $0.operationId == operationId }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.expectedStateVersion = command.expectedStateVersion
            existing.actionType = command.actionType.rawValue
            existing.gameId = command.gameId
            existing.played = command.played
            existing.targetOperationId = command.targetOperationId
            try? context.save()
            return
        }

        let existingOperations = (try? context.fetch(FetchDescriptor<SDCanonicalOperation>())) ?? []
        let nextSequence = (existingOperations.map(\.sequence).max() ?? 0) + 1
        context.insert(SDCanonicalOperation(
            operationId: command.operationId,
            expectedStateVersion: command.expectedStateVersion,
            actionType: command.actionType.rawValue,
            gameId: command.gameId,
            played: command.played,
            targetOperationId: command.targetOperationId,
            sequence: nextSequence
        ))
        try? context.save()
    }

    public func loadCanonicalDecisions() -> [CanonicalDecisionCommand] {
        guard let context = newContext() else { return [] }
        var descriptor = FetchDescriptor<SDCanonicalOperation>()
        descriptor.sortBy = [SortDescriptor(\.sequence, order: .forward)]
        let operations = (try? context.fetch(descriptor)) ?? []
        return operations.compactMap { operation in
            guard let actionType = CanonicalDecisionActionType(rawValue: operation.actionType) else {
                return nil
            }
            return CanonicalDecisionCommand(
                operationId: operation.operationId,
                expectedStateVersion: operation.expectedStateVersion,
                actionType: actionType,
                gameId: operation.gameId,
                played: operation.played,
                targetOperationId: operation.targetOperationId
            )
        }
    }

    public func updateCanonicalDecisionExpectedVersion(operationId: String, stateVersion: String) {
        guard let context = newContext() else { return }
        let id = operationId
        let descriptor = FetchDescriptor<SDCanonicalOperation>(
            predicate: #Predicate { $0.operationId == id }
        )
        guard let operation = try? context.fetch(descriptor).first else { return }
        operation.expectedStateVersion = stateVersion
        try? context.save()
    }

    public func removeCanonicalDecision(operationId: String) {
        guard let context = newContext() else { return }
        let id = operationId
        let descriptor = FetchDescriptor<SDCanonicalOperation>(
            predicate: #Predicate { $0.operationId == id }
        )
        guard let operation = try? context.fetch(descriptor).first else { return }
        context.delete(operation)
        try? context.save()
    }

    // MARK: - Pending Actions

    public func enqueuePendingAction(gameId: String, actionType: String, payload: Data) {
        guard let context = newContext() else { return }
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
        guard let context = newContext() else { return [] }
        var descriptor = FetchDescriptor<SDPendingAction>()
        descriptor.sortBy = [SortDescriptor(\.createdAt, order: .forward)]
        return (try? context.fetch(descriptor)) ?? []
    }

    public func removePendingAction(id: String) {
        guard let context = newContext() else { return }
        let descriptor = FetchDescriptor<SDPendingAction>(predicate: #Predicate { $0.id == id })
        guard let existing = try? context.fetch(descriptor).first else { return }
        context.delete(existing)
        try? context.save()
    }

    public func removePendingAction(gameId: String, actionType: String) {
        guard let context = newContext() else { return }
        let descriptor = FetchDescriptor<SDPendingAction>(
            predicate: #Predicate { $0.gameId == gameId && $0.actionType == actionType }
        )
        guard let existing = try? context.fetch(descriptor).first else { return }
        context.delete(existing)
        try? context.save()
    }

    /// An authoritative snapshot supersedes every legacy PATCH/DELETE. Those commands
    /// have no state-version guard, so retaining any of them could overwrite N+1.
    public func removePendingActions() {
        guard let context = newContext() else { return }
        let descriptor = FetchDescriptor<SDPendingAction>()
        guard let pending = try? context.fetch(descriptor) else { return }
        pending.forEach(context.delete)
        try? context.save()
    }

    // MARK: - Full Wipe

    public func deleteAllLocalData() {
        defer {
            UserDefaults.standard.removeObject(forKey: "playfit.onboarding.likedIds")
            UserDefaults.standard.removeObject(forKey: "playfit.onboarding.dislikedIds")
            UserDefaults.standard.removeObject(forKey: "playfit.onboarding.completedAt")
        }
        guard let context = newContext() else { return }
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
        if let snapshots = try? context.fetch(FetchDescriptor<SDAuthoritativeSnapshot>()) {
            for snapshot in snapshots { context.delete(snapshot) }
        }
        if let canonical = try? context.fetch(FetchDescriptor<SDCanonicalOperation>()) {
            for operation in canonical { context.delete(operation) }
        }
        try? context.save()
    }
}
