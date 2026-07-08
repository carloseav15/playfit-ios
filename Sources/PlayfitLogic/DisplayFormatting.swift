import Foundation

/// Turns a raw catalog tag/genre slug (e.g. "precision_platformer") into a
/// display label (e.g. "Precision Platformer"), matching the web's `formatTagLabel`.
public func formatTagLabel(_ tag: String) -> String {
    tag
        .split(separator: "_")
        .map { part in part.isEmpty ? String(part) : part.prefix(1).uppercased() + part.dropFirst() }
        .joined(separator: " ")
}

private let genreAcronyms: Set<String> = ["jrpg", "rpg", "fps", "mmo", "rts"]

/// Formats a raw catalog genre string for display (Title Case, with known
/// acronyms kept upper case), matching the web's `formatDisplayGenre`.
/// Returns "" for a missing or "unknown" genre, same as the web.
public func formatDisplayGenre(_ genre: String?) -> String {
    guard let genre, !genre.isEmpty, genre.lowercased() != "unknown" else { return "" }

    let normalized = genre
        .replacingOccurrences(of: "[;_/-]+", with: " ", options: .regularExpression)
        .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespaces)

    return normalized
        .split(separator: " ")
        .map { word -> String in
            let lower = word.lowercased()
            if genreAcronyms.contains(lower) { return lower.uppercased() }
            guard let first = lower.first else { return lower }
            return first.uppercased() + lower.dropFirst()
        }
        .joined(separator: " ")
}

public func isValidReleaseYear(_ year: String?) -> Bool {
    guard let year, year != "0000" else { return false }
    return year.range(of: #"^\d{4}$"#, options: .regularExpression) != nil
}
