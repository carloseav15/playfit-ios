import PlayfitDesignSystem
import PlayfitModels
import PlayfitLogic
import SwiftUI

public struct TasteMapVisualizerView: View {
    @Environment(\.playViewModel) private var viewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var activeNodeId: String?
    
    public init() {}
    
    struct GameNode: Identifiable {
        let id: String
        let game: Game
        let x: Double
        let y: Double
        let type: NodeType
        
        enum NodeType {
            case liked, avoided, pending
        }
    }
    
    public var body: some View {
        let nodes = getNodes()
        let activeNode = nodes.first { $0.id == activeNodeId } ?? nodes.first
        
        ZStack {
            Color.playfitBackground.ignoresSafeArea()
            
            VStack(spacing: PlayfitSpacing.md) {
                // Header details
                Text("Visual graph of your gaming traits.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                // SVG Cartesian Space Canvas
                ZStack {
                    GeometryReader { geo in
                        let size = min(geo.size.width, geo.size.height)
                        let center = size / 2.0
                        let scale = size / 2.0 - 20.0
                        
                        ZStack {
                            // Circular Grid Levels
                            Circle().stroke(Color.primary.opacity(0.05), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                .frame(width: scale * 2)
                            Circle().stroke(Color.primary.opacity(0.05), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                .frame(width: scale * 1.2)
                            Circle().stroke(Color.primary.opacity(0.05), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                .frame(width: scale * 0.5)
                            
                            // Central Axis Lines
                            Path { path in
                                path.move(to: CGPoint(x: 20, y: center))
                                path.addLine(to: CGPoint(x: size - 20, y: center))
                                path.move(to: CGPoint(x: center, y: 20))
                                path.addLine(to: CGPoint(x: center, y: size - 20))
                            }
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1.2)
                            
                            // Quadrant Label overlay texts
                            VStack {
                                HStack {
                                    Text("Chill & Open World").font(.caption2.bold())
                                    Spacer()
                                    Text("Complex & Systems").font(.caption2.bold())
                                }
                                Spacer()
                                HStack {
                                    Text("Cozy & Story-Rich").font(.caption2.bold())
                                    Spacer()
                                    Text("Demanding & Linear").font(.caption2.bold())
                                }
                            }
                            .foregroundColor(.secondary.opacity(0.7))
                            .padding(24)
                            .dynamicTypeSize(...DynamicTypeSize.large)
                            .accessibilityHidden(true)
                            
                            // Axis Directions
                            Text("Demanding →").font(.caption2.bold())
                                .position(x: size - 45, y: center - 10)
                                .dynamicTypeSize(...DynamicTypeSize.large)
                                .accessibilityHidden(true)
                            Text("← Cozy").font(.caption2.bold())
                                .position(x: 40, y: center - 10)
                                .dynamicTypeSize(...DynamicTypeSize.large)
                                .accessibilityHidden(true)
                            Text("Systems ↑").font(.caption2.bold())
                                .position(x: center - 35, y: 35)
                                .dynamicTypeSize(...DynamicTypeSize.large)
                                .accessibilityHidden(true)
                            Text("Story ↓").font(.caption2.bold())
                                .position(x: center - 25, y: size - 35)
                                .dynamicTypeSize(...DynamicTypeSize.large)
                                .accessibilityHidden(true)
                            
                            // Plot Nodes
                            ForEach(nodes) { node in
                                let cx = center + (node.x / 100.0) * scale
                                let cy = center - (node.y / 100.0) * scale // Cartesian invert
                                let isSelected = activeNode?.id == node.id
                                
                                Button {
                                    withAnimation(reduceMotion ? nil : .spring(response: 0.3)) {
                                        activeNodeId = node.id
                                    }
                                } label: {
                                    ZStack {
                                        Circle().fill(Color.clear).frame(width: 44, height: 44)
                                        Circle()
                                            .fill(nodeColor(node.type).opacity(isSelected ? 0.35 : 0.15))
                                            .frame(width: isSelected ? 24 : 16)
                                            .animation(reduceMotion ? nil : .spring(response: 0.3), value: isSelected)
                                        Circle()
                                            .fill(nodeColor(node.type))
                                            .frame(width: isSelected ? 10 : 8)
                                            .overlay(Circle().stroke(Color.white, lineWidth: 1.2))
                                    }
                                }
                                .buttonStyle(.plain)
                                .position(x: cx, y: cy)
                                .accessibilityLabel("\(node.game.title), \(nodeTypeLabel(node.type))")
                                .accessibilityHint("Shows this game below the map")
                            }
                        }
                        .frame(width: size, height: size)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    }
                }
                .aspectRatio(1.0, contentMode: .fit)
                .background(Color.white.opacity(0.01), in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                .padding(.horizontal)
                
                // Game Preview Carousel
                if let activeNode = activeNode {
                    carouselCard(activeNode, totalCount: nodes.count, currentIndex: nodes.firstIndex { $0.id == activeNode.id } ?? 0) {
                        // Previous action
                        if let idx = nodes.firstIndex(where: { $0.id == activeNode.id }) {
                            let prevIdx = idx == 0 ? nodes.count - 1 : idx - 1
                            if prevIdx < nodes.count {
                                activeNodeId = nodes[prevIdx].id
                            }
                        }
                    } onNext: {
                        // Next action
                        if let idx = nodes.firstIndex(where: { $0.id == activeNode.id }) {
                            let nextIdx = idx == nodes.count - 1 ? 0 : idx + 1
                            if nextIdx < nodes.count {
                                activeNodeId = nodes[nextIdx].id
                            }
                        }
                    }
                    .padding()
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom)))
                } else {
                    Spacer()
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Interactive Affinity Map")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private static let terminalStatuses: Set<PlayStatus> = [.beaten, .completed, .abandoned, .dropped]

    private func classify(_ state: UserGameState) -> GameNode.NodeType {
        let hasRating = (state.rating ?? 0) > 0
        let isPlaying = state.status == .playing
        let isTerminal = state.status.map { Self.terminalStatuses.contains($0) } ?? false

        if state.inPlayfitPicks && !isPlaying && !hasRating {
            return .pending
        }
        let isLiked = isPlaying
            || (state.rating ?? 0) >= 4.0
            || (isTerminal && (state.rating ?? 0) >= 3.0)
        return isLiked ? .liked : .avoided
    }

    private func getNodes() -> [GameNode] {
        var list: [GameNode] = []
        for (gameId, state) in viewModel.gameStates {
            guard let game = viewModel.gamesCache[gameId] else { continue }
            let type = classify(state)
            let coords = calculateGameCoordinates(game)
            list.append(GameNode(id: game.id, game: game, x: coords.x, y: coords.y, type: type))
        }
        return list
    }
    
    private func nodeColor(_ type: GameNode.NodeType) -> Color {
        switch type {
        case .liked: Color.playfitPositive
        case .avoided: Color.playfitNegative
        case .pending: Color.secondary.opacity(0.8)
        }
    }

    private func nodeTypeLabel(_ type: GameNode.NodeType) -> String {
        switch type {
        case .liked: "liked"
        case .avoided: "avoided"
        case .pending: "saved pick"
        }
    }
    
    private func carouselCard(_ node: GameNode, totalCount: Int, currentIndex: Int, onPrev: @escaping () -> Void, onNext: @escaping () -> Void) -> some View {
        PlayfitGlassCard {
            HStack(spacing: PlayfitSpacing.md) {
                // Carousel Navigation Left
                Button(action: onPrev) {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Previous game")

                PlayfitGameCover(game: node.game)
                    .frame(width: 52)
                
                // Center info block
                VStack(alignment: .leading, spacing: PlayfitSpacing.xs) {
                    HStack {
                        Text(node.game.primaryGenre.capitalized)
                            .font(.caption2.bold())
                            .foregroundColor(.playfitAccent)
                        Spacer()
                        Text(node.type == .liked ? "Liked" : (node.type == .avoided ? "Avoided" : "Saved"))
                            .font(.caption2.bold())
                            .foregroundColor(nodeColor(node.type))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(nodeColor(node.type).opacity(0.12), in: Capsule())
                    }
                    
                    Text(node.game.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        ForEach(node.game.tags.prefix(2), id: \.self) { tag in
                            Text(formatTagLabel(tag))
                                .font(.caption2.monospaced().weight(.semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Carousel Navigation Right
                Button(action: onNext) {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Next game")
            }
            .padding(12)
        }
    }
    
    private func calculateGameCoordinates(_ game: Game) -> GameCoordinate {
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
            let genre = (game.primaryGenre).lowercased()
            if genre.contains("rpg") || genre.contains("role_playing") {
                x += 10.0
                y -= 20.0
            } else if genre.contains("action") || genre.contains("shooter") {
                x += 20.0
                y += 15.0
            } else if genre.contains("adventure") || genre.contains("indie") {
                x -= 15.0
                y -= 15.0
            } else if genre.contains("strategy") || genre.contains("simulation") {
                x += 25.0
                y += 25.0
            } else if genre.contains("puzzle") || genre.contains("casual") {
                x -= 25.0
                y += 20.0
            }
        }
        
        // Deterministic jitter based on game.id
        var hash = 0
        for char in game.id.utf8 {
            hash = Int(char) &+ ((hash &<< 5) &- hash)
        }
        let jitterX = Double((hash % 16) - 8)
        let jitterY = Double(((hash >> 4) % 16) - 8)
        
        x += jitterX
        y += jitterY
        
        return GameCoordinate(
            x: max(-90.0, min(90.0, x)),
            y: max(-90.0, min(90.0, y))
        )
    }
}

struct GameCoordinate {
    let x: Double
    let y: Double
}
