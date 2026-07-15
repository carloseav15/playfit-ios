import Foundation

import PlayfitAPI
import PlayfitDesignSystem
import PlayfitFeatures
import PlayfitLogic
import PlayfitMocks
import PlayfitModels

// API client checks
let deviceId = DeviceID.loadOrCreate()
precondition(UUID(uuidString: deviceId) != nil, "Expected valid device UUID")
let httpClient: PlayfitAPIClient = HTTPPlayfitClient()
precondition(type(of: httpClient) == HTTPPlayfitClient.self, "Expected HTTPPlayfitClient")

// Game JSON decoding (web API format: gameId, externalCoverUrl)
let gameJSON = """
{"gameId":"test","title":"Test Game","externalCoverUrl":"https://example.com/cover.jpg","series":"Test Series","primaryGenre":"Action","tags":["fun"],"availablePlatformIds":["pc"],"availablePlatformNames":["PC"],"releaseState":"released","releaseYear":"2024"}
"""
let gameData = gameJSON.data(using: .utf8)!
let decodedGame = try JSONDecoder().decode(Game.self, from: gameData)
precondition(decodedGame.id == "test", "Expected gameId to decode as id")
precondition(decodedGame.title == "Test Game", "Expected title")
precondition(decodedGame.coverURL?.absoluteString == "https://example.com/cover.jpg", "Expected coverURL from externalCoverUrl")
precondition(decodedGame.series == "Test Series", "Expected series")

let ranked = MockPlayfitData.rankedRecommendations
precondition(!ranked.isEmpty, "Expected ranked recommendations")
precondition(ranked[0].affinityScore == 94, "Expected affinityScore 94")
precondition(ranked[0].confidence == .high, "Expected high confidence")
precondition(decisionLabel(for: ranked[0]) == "Strong match", "Expected Strong match label")
precondition(decisionTone(for: ranked[0]) == .positive, "Expected positive tone")
precondition(matchQualityLabel(80) == "Strong match", "Expected Strong match quality")
precondition(watchOutLabel(60) == "High friction", "Expected High friction watch-out")
precondition(confidenceLabel(.high) == "Strong signal", "Expected Strong signal confidence")
precondition(filterUsefulCautions(["No major caveat yet."]).isEmpty, "Expected empty cautions")
precondition(filterUsefulCautions(["Some real caution"]).count == 1, "Expected one caution")
precondition(isValidReleaseYear("2023") == true, "Expected valid year")
precondition(isValidReleaseYear(nil) == false, "Expected invalid year")
precondition(recommendationGroupTitle(for: ranked) == "Best matches", "Expected Best matches")

// Profile checks
let profile = MockPlayfitData.userProfile
precondition(!profile.summary.isEmpty, "Expected profile summary")
precondition(profile.ratedCount == 12, "Expected ratedCount 12")
precondition(profile.signals.count == 2, "Expected 2 signals")

// Feedback logic checks
var gameStates: [String: UserGameState] = [:]
let metroidId = "metroid_prime_remastered"
applyDecisionFeedback(gameStates: &gameStates, gameId: metroidId, feedback: .playedLoved)
precondition(gameStates[metroidId]?.status == .completed, "Feedback: expected completed")
precondition(gameStates[metroidId]?.rating == 5, "Feedback: expected rating 5")

applyDecisionFeedback(gameStates: &gameStates, gameId: "hades", feedback: .notForMe)
precondition(gameStates["hades"]?.excluded == true, "Feedback: expected excluded")
precondition(gameStates["hades"]?.rating == 2, "Feedback: expected rating 2")

// Taste model checks
gameStates["hades"] = UserGameState(inPlayfitPicks: true, updatedAt: "2024-01-01T00:00:00Z")
let history = buildHistoryAndActivityEntries(
    gameStates: gameStates,
    games: MockPlayfitData.rankedRecommendations.map(\.game)
)
precondition(history.contains { $0.gameId == "hades" }, "Expected Hades in history")
precondition(history.first?.decision == "picks", "Expected picks decision")

// ViewModel checks
let vm = PlayViewModel(recommendations: ranked, profile: profile)
precondition(vm.primary != nil, "Expected primary recommendation")
precondition(vm.primary?.game.id == "metroid_prime_remastered", "Expected Metroid as primary")
precondition(!vm.picks.isEmpty, "Expected picks")
precondition(vm.picks.contains { $0.game.id == "metroid_prime_remastered" }, "Expected Metroid in picks")
precondition(vm.isPicked("metroid_prime_remastered"), "Expected Metroid isPicked")

// Component instantiation checks
_ = RecommendationMetric(label: "Test", value: "Test", numericValue: 50)
_ = FitReasonsCard(title: "Test", reasons: ["Test"], tone: DecisionTone.positive)

_ = PlayfitRootView()

print("Playfit iOS smoke check passed")
