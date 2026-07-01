import Foundation

public enum APIError: LocalizedError {
    case invalidURL
    case network(Error)
    case decoding(Error)
    case server(Int, String?)
    case unexpectedResponse

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid API URL"
        case .network(let error):
            "Network error: \(error.localizedDescription)"
        case .decoding(let error):
            "Decoding error: \(error.localizedDescription)"
        case .server(429, _):
            "Too many requests. Please wait a moment and try again."
        case .server(let code, let body):
            "Server error \(code): \(body ?? "unknown")"
        case .unexpectedResponse:
            "Unexpected response format"
        }
    }
}
