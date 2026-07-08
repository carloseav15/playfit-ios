import Foundation
import PlayfitModels

public let highFrictionThreshold = 58
public let strongFitThreshold = 78
public let promisingFitThreshold = 62

public func rebuildUserProfile(
    onboardingLikedIds: [String],
    onboardingDislikedIds: [String],
    gameStates: [String: UserGameState],
    gamesCache: [String: Game]
) -> UserProfile {
    let dislikedOnboarding = Set(onboardingDislikedIds)
    let likedOnboarding = onboardingLikedIds.filter { !dislikedOnboarding.contains($0) }
    var likedGenres: [String] = []
    var avoidedGenres: [String] = []
    var likedTags: [String: Int] = [:]
    var dislikedTags: [String: Int] = [:]
    var ratedCount = 0
    var positiveOutcomeCount = 0
    var negativeOutcomeCount = 0
    var ratedIds = Set<String>()

    func add(_ value: String, to values: inout [String]) {
        guard !value.isEmpty, !values.contains(value) else { return }
        values.append(value)
    }

    for gameId in likedOnboarding {
        guard let game = gamesCache[gameId] else { continue }
        add(game.primaryGenre, to: &likedGenres)
        for tag in game.tags { likedTags[tag, default: 0] += 1 }
    }

    for (gameId, state) in gameStates {
        guard let rating = state.rating, rating > 0, let game = gamesCache[gameId] else { continue }
        ratedIds.insert(gameId)
        ratedCount += 1
        if rating >= 4 {
            positiveOutcomeCount += 1
            add(game.primaryGenre, to: &likedGenres)
            for tag in game.tags { likedTags[tag, default: 0] += 1 }
        } else if rating <= 2 {
            negativeOutcomeCount += 1
            add(game.primaryGenre, to: &avoidedGenres)
            for tag in game.tags { dislikedTags[tag, default: 0] += 1 }
        }
    }

    for gameId in dislikedOnboarding where !ratedIds.contains(gameId) {
        guard let game = gamesCache[gameId] else { continue }
        ratedCount += 1
        negativeOutcomeCount += 1
        add(game.primaryGenre, to: &avoidedGenres)
        for tag in game.tags { dislikedTags[tag, default: 0] += 1 }
    }

    for tag in Set(likedTags.keys).intersection(dislikedTags.keys) {
        let positive = likedTags[tag, default: 0]
        let negative = dislikedTags[tag, default: 0]
        if positive > negative {
            dislikedTags.removeValue(forKey: tag)
        } else if negative > positive {
            likedTags.removeValue(forKey: tag)
        } else {
            likedTags.removeValue(forKey: tag)
            dislikedTags.removeValue(forKey: tag)
        }
    }

    let topLikedTags = likedTags.sorted { left, right in
        left.value == right.value ? left.key < right.key : left.value > right.value
    }.prefix(3)
    let topDislikedTags = dislikedTags.sorted { left, right in
        left.value == right.value ? left.key < right.key : left.value > right.value
    }.prefix(3)
    var signals: [ProfileSignal] = []

    func traitLabel(_ value: String) -> String {
        value.replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
    }

    for (tag, count) in topLikedTags {
        let label: String
        let reason: String
        if ratedCount >= 6 {
            label = "Strong pattern: \(traitLabel(tag))"
            reason = "\(count) positive outcomes point in this direction."
        } else if ratedCount >= 3 {
            label = "Emerging pattern: \(traitLabel(tag))"
            reason = "Several favorites or high ratings share this trait."
        } else {
            label = "Early signal: \(traitLabel(tag))"
            reason = "This shows up in your favorites or first ratings. Rate more games to confirm it."
        }
        signals.append(ProfileSignal(id: "tag-fit-\(tag)", tone: .positive, label: label, reason: reason))
    }

    for (tag, count) in topDislikedTags {
        let label: String
        let reason: String
        if ratedCount >= 6 {
            label = "Clear watch-out: \(traitLabel(tag))"
            reason = "\(count) lower-rated outcomes lean this way more than your positive signals."
        } else if ratedCount >= 3 {
            label = "Emerging watch-out: \(traitLabel(tag))"
            reason = "A few lower ratings point in this direction."
        } else {
            label = "Possible watch-out: \(traitLabel(tag))"
            reason = "There is not enough lower-rated evidence to treat this as a firm pattern yet."
        }
        signals.append(ProfileSignal(id: "tag-risk-\(tag)", tone: .negative, label: label, reason: reason))
    }

    if positiveOutcomeCount >= 3 && negativeOutcomeCount == 0 {
        signals.append(ProfileSignal(
            id: "positive-momentum",
            tone: .positive,
            label: "Clean streak",
            reason: "Your recent ratings are positive, so Playfit can lean into nearby matches."
        ))
    }

    let summary: String
    if ratedCount >= 6 {
        summary = "Strong pattern from \(ratedCount) ratings and \(likedOnboarding.count) setup favorites."
    } else if ratedCount >= 3 {
        summary = "Emerging pattern from \(ratedCount) ratings and \(likedOnboarding.count) setup favorites."
    } else if ratedCount > 0 {
        summary = "Early read from \(ratedCount) rating(s) and \(likedOnboarding.count) setup favorites."
    } else {
        summary = "Early profile built from your favorites. Rate a few games to make it sharper."
    }

    return UserProfile(
        summary: summary,
        likedGenres: Array(likedGenres.prefix(5)),
        avoidedGenres: Array(avoidedGenres.prefix(3)),
        likedTags: likedTags,
        dislikedTags: dislikedTags,
        ratedCount: ratedCount,
        signals: Array(signals.prefix(8))
    )
}
