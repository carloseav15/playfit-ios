import Foundation
import PlayfitModels

// MARK: - Thresholds

public let highFrictionThreshold = 58
public let strongFitThreshold = 78
public let promisingFitThreshold = 62

// MARK: - Feedback Logic

private func feedbackRating(for feedback: DecisionFeedback) -> Double? {
    switch feedback {
    case .loved, .playedLoved: 5
    case .liked, .playedLiked: 4
    case .mixed, .playedMixed: 3
    case .notForMe, .playedDropped: 2
    default: nil
    }
}

@discardableResult
public func applyDecisionFeedback(
    gameStates: inout [String: UserGameState],
    gameId: String,
    feedback: DecisionFeedback
) -> UserGameState {
    applyDecisionFeedback(gameStates: &gameStates, gameId: gameId, feedback: feedback, timestamp: nowIso())
}

@discardableResult
public func applyDecisionFeedback(
    gameStates: inout [String: UserGameState],
    gameId: String,
    feedback: DecisionFeedback,
    timestamp: String
) -> UserGameState {
    let existing = gameStates[gameId] ?? UserGameState()
    var next = existing
    next.updatedAt = timestamp

    switch feedback {
    case .play:
        next.status = .playing
        next.inBacklog = false
        next.inPlayfitPicks = false
        next.excluded = false
    case .later:
        next.status = .shelved
        next.inBacklog = true
        next.excluded = false
    case .playedLoved, .playedLiked, .playedMixed:
        next.status = .completed
        next.inBacklog = false
        next.inPlayfitPicks = false
        next.excluded = false
    case .playedDropped:
        next.status = .abandoned
        next.inBacklog = false
        next.inPlayfitPicks = false
        next.excluded = true
    default:
        break
    }

    if let rating = feedbackRating(for: feedback) {
        next.rating = rating
        next.excluded = (feedback == .notForMe || feedback == .playedDropped)
        if next.excluded || feedback.isPlayed {
            next.inPlayfitPicks = false
        }
    }

    gameStates[gameId] = next
    return next
}

// MARK: - Labels & Tone

public func confidenceLabel(_ value: Confidence) -> String {
    switch value {
    case .high: "Strong signal"
    case .medium: "Building signal"
    case .low: "First look"
    }
}

public func decisionTone(for entry: RankedRecommendation) -> DecisionTone {
    if entry.riskScore >= highFrictionThreshold { return .negative }
    if entry.confidence == .low { return .warning }
    if entry.affinityScore >= strongFitThreshold && entry.riskScore <= 35 { return .positive }
    if entry.affinityScore >= promisingFitThreshold { return .info }
    return .warning
}

public func decisionLabel(for entry: RankedRecommendation) -> String {
    if entry.riskScore >= highFrictionThreshold { return "Watch out" }
    if entry.confidence == .low { return "Too early to tell" }
    if entry.affinityScore >= strongFitThreshold { return "Strong match" }
    if entry.affinityScore >= promisingFitThreshold { return "Promising" }
    return "Still learning"
}

public func matchQualityLabel(_ score: Int) -> String {
    if score >= strongFitThreshold { return "Strong match" }
    if score >= promisingFitThreshold { return "Promising" }
    if score >= 35 { return "Moderate match" }
    return "Early match"
}

public func watchOutLabel(_ score: Int) -> String {
    if score >= highFrictionThreshold { return "High friction" }
    if score >= 35 { return "Some watch-outs" }
    if score >= 15 { return "Low watch-out" }
    return "Clear read"
}

public func primaryReason(for entry: RankedRecommendation) -> String {
    if entry.riskScore >= highFrictionThreshold, let caution = entry.cautionReasons.first {
        return caution
    }
    return entry.fitReasons.first ?? "Rate a few more games to strengthen this signal."
}

public func recommendationGroupTitle(for entries: [RankedRecommendation]) -> String {
    if entries.allSatisfy({ $0.confidence == .low }) {
        return "First reads"
    }
    return "Best matches"
}

// MARK: - Helpers

private let emptyCautionLabels: Set<String> = [
    "No reliable call yet.",
    "No major watch-out yet.",
    "No major caveat yet.",
]

public func filterUsefulCautions(_ cautions: [String]) -> [String] {
    cautions.filter { reason in
        let trimmed = reason.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && !emptyCautionLabels.contains(trimmed)
    }
}

public func isValidReleaseYear(_ year: String?) -> Bool {
    guard let year, year != "0000" else { return false }
    return year.range(of: #"^\d{4}$"#, options: .regularExpression) != nil
}

// MARK: - Taste Model

public func buildHistoryAndActivityEntries(
    gameStates: [String: UserGameState],
    games: [Game]
) -> [TasteHistoryEntry] {
    let gamesById = Dictionary(uniqueKeysWithValues: games.map { ($0.id, $0) })
    var entries: [TasteHistoryEntry] = []

    for (gameId, state) in gameStates {
        guard let game = gamesById[gameId] else { continue }
        let terminal: Set<PlayStatus> = [.completed, .beaten, .abandoned]
        let isActivePick = state.inPlayfitPicks && !terminal.contains(state.status ?? .backlog) && !state.excluded
        guard isActivePick else { continue }
        entries.append(TasteHistoryEntry(
            gameId: gameId,
            title: game.title,
            decision: "picks",
            source: "active_state",
            rating: state.rating,
            status: state.status,
            updatedAt: state.updatedAt,
            traits: [game.primaryGenre] + game.tags
        ))
    }

    return entries.sorted { a, b in
        let aTime = a.updatedAt ?? ""
        let bTime = b.updatedAt ?? ""
        return aTime > bTime || (aTime == bTime && a.title.localizedCompare(b.title) == .orderedAscending)
    }
}

// MARK: - Internal

func nowIso() -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: Date())
}

public func buildTasteHistoryEntries(
    gameStates: [String: UserGameState],
    onboardingLikedIds: [String],
    onboardingDislikedIds: [String],
    gamesCache: [String: Game]
) -> [TasteHistoryEntry] {
    var entriesByGame: [String: TasteHistoryEntry] = [:]
    
    // 1. Ratings & Picks
    for (gameId, state) in gameStates {
        guard let game = gamesCache[gameId] else { continue }
        let rating = state.rating
        let status = state.status
        let decision: String
        let tone: String?
        
        if state.inPlayfitPicks && (rating == nil || rating == 0) && (status == nil || status == .backlog) {
            decision = "picks"
            tone = nil
        } else if let r = rating {
            decision = r >= 4 ? "liked" : "not_for_me"
            tone = r >= 4 ? "positive" : "negative"
        } else if let s = status, s == .abandoned {
            decision = "dropped"
            tone = "negative"
        } else {
            continue
        }
        
        entriesByGame[gameId] = TasteHistoryEntry(
            gameId: gameId,
            title: game.title,
            decision: decision,
            source: "rating",
            tone: tone,
            rating: rating,
            status: status,
            updatedAt: state.updatedAt,
            traits: [game.primaryGenre] + game.tags
        )
    }
    
    // 2. Onboarding Liked
    for gameId in onboardingLikedIds {
        if entriesByGame[gameId] != nil { continue }
        guard let game = gamesCache[gameId] else { continue }
        entriesByGame[gameId] = TasteHistoryEntry(
            gameId: gameId,
            title: game.title,
            decision: "setup_favorite",
            source: "onboarding_liked",
            tone: "positive",
            traits: [game.primaryGenre] + game.tags
        )
    }
    
    // 3. Onboarding Disliked
    for gameId in onboardingDislikedIds {
        if entriesByGame[gameId] != nil { continue }
        guard let game = gamesCache[gameId] else { continue }
        entriesByGame[gameId] = TasteHistoryEntry(
            gameId: gameId,
            title: game.title,
            decision: "setup_miss",
            source: "onboarding_disliked",
            tone: "negative",
            traits: [game.primaryGenre] + game.tags
        )
    }
    
    return Array(entriesByGame.values).sorted { left, right in
        let leftTime = left.updatedAt ?? ""
        let rightTime = right.updatedAt ?? ""
        if leftTime != rightTime {
            return leftTime > rightTime
        }
        return left.title.localizedCompare(right.title) == .orderedAscending
    }
}

public func buildTasteMapTraits(
    historyEntries: [TasteHistoryEntry],
    profile: UserProfile
) -> [TasteMapTrait] {
    var counts: [String: (positive: Int, negative: Int, kind: String, label: String)] = [:]
    
    // 1. Count from history
    for entry in historyEntries {
        let isPositive = entry.tone == "positive"
        let isNegative = entry.tone == "negative"
        guard isPositive || isNegative else { continue }
        
        for trait in entry.traits {
            let isTag = trait.contains("_") || trait.count > 12
            let kind = isTag ? "tag" : "genre"
            let label = trait.replacingOccurrences(of: "_", with: " ").capitalized
            
            let cur = counts[trait] ?? (0, 0, kind, label)
            counts[trait] = (
                cur.positive + (isPositive ? 1 : 0),
                cur.negative + (isNegative ? 1 : 0),
                kind,
                label
            )
        }
    }
    
    // 2. Integrate profile preferences
    for genre in profile.likedGenres {
        let label = genre.capitalized
        let cur = counts[genre] ?? (0, 0, "genre", label)
        counts[genre] = (cur.positive + 1, cur.negative, "genre", label)
    }
    for genre in profile.avoidedGenres {
        let label = genre.capitalized
        let cur = counts[genre] ?? (0, 0, "genre", label)
        counts[genre] = (cur.positive, cur.negative + 1, "genre", label)
    }
    
    // 3. Build Traits
    var traitsList: [TasteMapTrait] = []
    for (id, val) in counts {
        let pos = val.positive
        let neg = val.negative
        let total = pos + neg
        guard total > 0 else { continue }
        
        let direction = pos >= neg ? "positive" : "negative"
        let net = abs(pos - neg)
        let strength = Double(net) * 10.0
        
        traitsList.append(TasteMapTrait(
            id: id,
            label: val.label,
            kind: val.kind,
            positiveCount: pos,
            negativeCount: neg,
            netScore: net,
            strength: min(strength, 100.0),
            confidence: total >= 3 ? .high : (total >= 2 ? .medium : .low),
            direction: direction
        ))
    }
    
    return traitsList.sorted { left, right in
        if left.strength != right.strength {
            return left.strength > right.strength
        }
        return left.label.localizedCompare(right.label) == .orderedAscending
    }
}
