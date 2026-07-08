import Foundation
import PlayfitModels

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

@discardableResult
public func setPlayfitPick(
    gameStates: inout [String: UserGameState],
    gameId: String,
    picked: Bool,
    timestamp: String? = nil
) -> UserGameState {
    var next = gameStates[gameId] ?? UserGameState()
    let resolvedTimestamp = timestamp ?? nowIso()
    if next.createdAt.isEmpty {
        next.createdAt = resolvedTimestamp
    }
    next.updatedAt = resolvedTimestamp
    next.inPlayfitPicks = picked
    gameStates[gameId] = next
    return next
}
