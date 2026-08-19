import Foundation

public enum APIError: LocalizedError {
    case invalidURL
    case decoding(Error)
    case server(Int, String?)
    case canonicalConflict(currentStateVersion: String?, undoUnavailable: Bool)
    case invalidCanonicalSnapshot(String)
    case unexpectedResponse

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid API URL"
        case .decoding(let error):
            "Decoding error: \(error.localizedDescription)"
        case .server(429, _):
            "Too many requests. Please wait a moment and try again."
        case .server(let code, let body):
            "Server error \(code): \(body ?? "unknown")"
        case .canonicalConflict(_, let undoUnavailable):
            undoUnavailable
                ? "That decision can no longer be undone."
                : "Your Playfit profile changed on another session."
        case .invalidCanonicalSnapshot(let reason):
            "Invalid canonical snapshot: \(reason)"
        case .unexpectedResponse:
            "Unexpected response format"
        }
    }
}
