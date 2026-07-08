import Foundation
import PlayfitModels

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

public func buildTasteHistoryEntries(
    gameStates: [String: UserGameState],
    onboardingLikedIds: [String],
    onboardingDislikedIds: [String],
    gamesCache: [String: Game]
) -> [TasteHistoryEntry] {
    var entriesByGame: [String: TasteHistoryEntry] = [:]

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
