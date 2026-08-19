import PlayfitModels

enum TasteMapGraph {
    struct GameNode: Identifiable {
        let id: String
        let game: Game
        let x: Double
        let y: Double
        let type: NodeType

        enum NodeType: Equatable {
            case liked, avoided, pending
        }
    }

    static func makeNodes(
        gameStates: [String: UserGameState],
        gamesCache: [String: Game],
        likedGameIds: [String],
        dislikedGameIds: [String]
    ) -> [GameNode] {
        var nodes: [GameNode] = []
        for (gameId, state) in gameStates {
            guard let game = gamesCache[gameId] else { continue }
            let type = classify(
                gameId: gameId,
                state: state,
                likedGameIds: likedGameIds,
                dislikedGameIds: dislikedGameIds
            )
            let coordinates = calculateCoordinates(for: game)
            nodes.append(GameNode(id: game.id, game: game, x: coordinates.x, y: coordinates.y, type: type))
        }
        return nodes
    }

    private static let terminalStatuses: Set<PlayStatus> = [.beaten, .completed, .abandoned, .dropped]

    private static func classify(
        gameId: String,
        state: UserGameState,
        likedGameIds: [String],
        dislikedGameIds: [String]
    ) -> GameNode.NodeType {
        if likedGameIds.contains(gameId) { return .liked }
        if dislikedGameIds.contains(gameId) { return .avoided }

        let hasRating = (state.rating ?? 0) > 0
        let isPlaying = state.status == .playing
        let isTerminal = state.status.map { terminalStatuses.contains($0) } ?? false
        if state.inPlayfitPicks && !isPlaying && !hasRating { return .pending }

        let isLiked = isPlaying
            || (state.rating ?? 0) >= 4.0
            || (isTerminal && (state.rating ?? 0) >= 3.0)
        return isLiked ? .liked : .avoided
    }

    private static func calculateCoordinates(for game: Game) -> GameCoordinate {
        var x = 0.0
        var y = 0.0
        let demandingTags = ["souls_like", "unforgiving", "demanding", "survival", "tactical", "deck_building", "stealth"]
        let chillTags = ["chill", "cozy", "accessible", "short_sessions", "pick_up_and_play", "lighthearted"]
        let systemsTags = ["open_world", "sandbox", "roguelike", "puzzle", "rhythm", "deck_building"]
        let storyTags = ["story_rich", "lore_heavy", "linear", "branching_narrative", "text_based", "horror", "dark"]

        for tag in game.tags {
            if demandingTags.contains(tag) { x += 28.0 }
            if chillTags.contains(tag) { x -= 28.0 }
            if systemsTags.contains(tag) { y += 28.0 }
            if storyTags.contains(tag) { y -= 28.0 }
        }

        if x == 0.0 && y == 0.0 {
            let genre = game.primaryGenre.lowercased()
            if genre.contains("rpg") || genre.contains("role_playing") {
                x += 10.0; y -= 20.0
            } else if genre.contains("action") || genre.contains("shooter") {
                x += 20.0; y += 15.0
            } else if genre.contains("adventure") || genre.contains("indie") {
                x -= 15.0; y -= 15.0
            } else if genre.contains("strategy") || genre.contains("simulation") {
                x += 25.0; y += 25.0
            } else if genre.contains("puzzle") || genre.contains("casual") {
                x -= 25.0; y += 20.0
            }
        }

        var hash = 0
        for character in game.id.utf8 {
            hash = Int(character) &+ ((hash &<< 5) &- hash)
        }
        x += Double((hash % 16) - 8)
        y += Double(((hash >> 4) % 16) - 8)

        return GameCoordinate(x: max(-90.0, min(90.0, x)), y: max(-90.0, min(90.0, y)))
    }
}

struct GameCoordinate {
    let x: Double
    let y: Double
}
