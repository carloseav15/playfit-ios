import Foundation
import PlayfitModels

public func buildTasteMapTraits(
    historyEntries: [TasteHistoryEntry],
    profile: UserProfile
) -> [TasteMapTrait] {
    var counts: [String: (positive: Int, negative: Int, kind: String, label: String)] = [:]

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
