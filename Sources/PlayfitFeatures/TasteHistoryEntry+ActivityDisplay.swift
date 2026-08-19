import PlayfitDesignSystem
import PlayfitModels
import SwiftUI

extension TasteHistoryEntry: Identifiable {
    public var id: String { gameId }
}

extension TasteHistoryEntry {
    var activityBadgeLabel: String {
        switch decision {
        case "picks": "Saved Pick"
        case "setup_favorite": "Setup: Loved"
        case "setup_miss": "Setup: Missed"
        case "loved": "Loved"
        case "liked": "Liked"
        case "mixed": "Mixed"
        case "dropped": "Dropped"
        case "not_for_me": "Not For Me"
        default: "Rated"
        }
    }

    var activityBadgeColor: Color {
        switch tone {
        case "positive": Color.playfitPositive
        case "negative": Color.playfitNegative
        default: Color.secondary
        }
    }

    var activityDateLabel: String {
        guard let updatedAt else { return "Baseline" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: updatedAt) else { return "Recent" }

        let output = DateFormatter()
        output.locale = Locale(identifier: "en_US_POSIX")
        output.calendar = Calendar(identifier: .gregorian)
        output.dateStyle = .medium
        output.timeStyle = .none
        return output.string(from: date)
    }
}
