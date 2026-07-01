import PlayfitDesignSystem
import PlayfitModels
import PlayfitLogic
import SwiftUI

public struct GamingTasteDNAView: View {
    @Environment(\.playViewModel) private var viewModel
    
    public init() {}
    
    public var body: some View {
        let history = buildTasteHistoryEntries(
            gameStates: viewModel.gameStates,
            onboardingLikedIds: [],
            onboardingDislikedIds: [],
            gamesCache: viewModel.gamesCache
        )
        let traits = buildTasteMapTraits(historyEntries: history, profile: viewModel.profile)
        
        ZStack {
            Color.playfitBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: PlayfitSpacing.lg) {
                    if traits.isEmpty {
                        Text("Add more taste decisions to draw a useful map.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    } else {
                        // Radar Chart
                        VStack(alignment: .center) {
                            Text("Gaming Taste DNA")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            
                            radarChart(traits)
                                .frame(height: 240)
                                .padding(.vertical, 16)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Loved Pillars (Positive Traits)
                        let loved = traits.filter { $0.direction == "positive" }
                        VStack(alignment: .leading, spacing: PlayfitSpacing.sm) {
                            Text("Loved Pillars")
                                .font(.caption.bold())
                                .foregroundColor(.playfitPositive)
                                .textCase(.uppercase)
                                .padding(.horizontal, 4)
                            
                            pillCloud(loved, tone: .positive)
                        }
                        
                        // Avoided Signals (Negative Traits)
                        let avoided = traits.filter { $0.direction == "negative" }
                        VStack(alignment: .leading, spacing: PlayfitSpacing.sm) {
                            Text("Avoided Signals")
                                .font(.caption.bold())
                                .foregroundColor(.playfitNegative)
                                .textCase(.uppercase)
                                .padding(.horizontal, 4)
                                .padding(.top, 8)
                            
                            pillCloud(avoided, tone: .negative)
                        }
                    }
                }
                .padding(PlayfitSpacing.md)
            }
        }
        .navigationTitle("Gaming DNA")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    @ViewBuilder
    private func radarChart(_ traits: [TasteMapTrait]) -> some View {
        let maxVal = traits.map(\.strength).max() ?? 1.0
        let displayTraits = Array(traits.prefix(5))
        let n = displayTraits.count
        
        if n >= 3 {
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let center = size / 2.0
                let radius = size / 2.0 - 45.0
                
                ZStack {
                    // Concentric Grid Lines (0.25, 0.5, 0.75, 1.0)
                    ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { level in
                        Path { path in
                            let r = radius * level
                            for i in 0..<n {
                                let angle = (Double(i) * 2.0 * .pi) / Double(n) - .pi / 2.0
                                let x = center + r * cos(angle)
                                let y = center + r * sin(angle)
                                if i == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                            path.closeSubpath()
                        }
                        .stroke(Color.primary.opacity(level == 1.0 ? 0.08 : 0.04), style: StrokeStyle(lineWidth: level == 1.0 ? 1 : 0.5, dash: level == 1.0 ? [] : [2, 2]))
                    }
                    
                    // Spokes & Labels
                    ForEach(0..<n, id: \.self) { i in
                        let trait = displayTraits[i]
                        let angle = (Double(i) * 2.0 * .pi) / Double(n) - .pi / 2.0
                        let spokeX = center + radius * cos(angle)
                        let spokeY = center + radius * sin(angle)
                        
                        let labelX = center + (radius + 24) * cos(angle)
                        let labelY = center + (radius + 12) * sin(angle)
                        
                        // Line
                        Path { path in
                            path.move(to: CGPoint(x: center, y: center))
                            path.addLine(to: CGPoint(x: spokeX, y: spokeY))
                        }
                        .stroke(Color.primary.opacity(0.04), lineWidth: 0.8)
                        
                        // Label
                        VStack(spacing: 2) {
                            Text(trait.label)
                                .font(.system(size: 7.5, weight: .black))
                                .foregroundColor(.primary)
                            Text("\(Int((trait.strength / maxVal) * 100))%")
                                .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                                .foregroundColor(trait.direction == "positive" ? .playfitAccent : .playfitNegative)
                        }
                        .position(x: labelX, y: labelY)
                    }
                    
                    // Scored Area Polygon
                    Path { path in
                        for i in 0..<n {
                            let trait = displayTraits[i]
                            let angle = (Double(i) * 2.0 * .pi) / Double(n) - .pi / 2.0
                            let val = (trait.strength / maxVal) * radius
                            let x = center + val * cos(angle)
                            let y = center + val * sin(angle)
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        path.closeSubpath()
                    }
                    .fill(Color.playfitAccent.opacity(0.18))
                    
                    Path { path in
                        for i in 0..<n {
                            let trait = displayTraits[i]
                            let angle = (Double(i) * 2.0 * .pi) / Double(n) - .pi / 2.0
                            let val = (trait.strength / maxVal) * radius
                            let x = center + val * cos(angle)
                            let y = center + val * sin(angle)
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        path.closeSubpath()
                    }
                    .stroke(Color.playfitAccent, lineWidth: 2)
                    
                    // Data Points
                    ForEach(0..<n, id: \.self) { i in
                        let trait = displayTraits[i]
                        let angle = (Double(i) * 2.0 * .pi) / Double(n) - .pi / 2.0
                        let val = (trait.strength / maxVal) * radius
                        let x = center + val * cos(angle)
                        let y = center + val * sin(angle)
                        
                        Circle()
                            .fill(trait.direction == "positive" ? Color.playfitAccent : Color.playfitNegative)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.2))
                            .position(x: x, y: y)
                    }
                }
                .frame(width: size, height: size)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        } else {
            Text("Radar chart requires at least 3 preference records.")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    @ViewBuilder
    private func pillCloud(_ traits: [TasteMapTrait], tone: ProfileSignalTone) -> some View {
        if traits.isEmpty {
            Text("No preference tags recorded yet.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
                .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
        } else {
            let maxStrength = traits.map(\.strength).max() ?? 1.0
            
            FlowLayout(spacing: 8) {
                ForEach(traits, id: \.id) { trait in
                    let isStrong = trait.strength >= maxStrength * 0.6
                    let isMedium = trait.strength >= maxStrength * 0.3 && trait.strength < maxStrength * 0.6
                    
                    HStack(spacing: PlayfitSpacing.xs) {
                        Text(trait.label)
                            .font(.system(
                                size: isStrong ? 12 : (isMedium ? 10.5 : 9.5),
                                weight: isStrong ? .black : (isMedium ? .bold : .medium)
                            ))
                            .foregroundColor(.primary.opacity(isStrong ? 0.95 : (isMedium ? 0.85 : 0.70)))
                        
                        Text("\(Int(trait.strength))")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(tone == .positive ? .playfitPositive : .playfitNegative)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1.5)
                            .background(Color.primary.opacity(0.04), in: Capsule())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(tone == .positive ? Color.playfitPositive.opacity(0.06) : Color.playfitNegative.opacity(0.06), in: Capsule())
                    .overlay(
                        Capsule().stroke(tone == .positive ? Color.playfitPositive.opacity(0.15) : Color.playfitNegative.opacity(0.15), lineWidth: 1)
                    )
                    .scaleEffect(isStrong ? 1.03 : 1.0)
                    .animation(.spring(response: 0.25), value: isStrong)
                }
            }
        }
    }
}

// Helper Layout container for wrapping views like nubes/tag clouds
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxRowHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width {
                x = 0
                y += maxRowHeight + spacing
                maxRowHeight = 0
            }
            x += size.width + spacing
            maxRowHeight = max(maxRowHeight, size.height)
        }
        height = y + maxRowHeight
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var maxRowHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += maxRowHeight + spacing
                maxRowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            maxRowHeight = max(maxRowHeight, size.height)
        }
    }
}
