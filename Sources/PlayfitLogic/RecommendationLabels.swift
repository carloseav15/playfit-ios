import Foundation
import PlayfitModels

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

public func recommendationGroupTitle(for entries: [RankedRecommendation]) -> String {
    if entries.allSatisfy({ $0.confidence == .low }) {
        return "First reads"
    }
    return "Best matches"
}

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
