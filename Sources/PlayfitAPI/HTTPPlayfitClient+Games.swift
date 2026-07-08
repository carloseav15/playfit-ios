import Foundation
import PlayfitModels

extension HTTPPlayfitClient {
    public func searchGames(query: String) async throws -> [Game] {
        let url = urlWithDevice("/api/games")
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        var items = components.queryItems ?? []
        items.append(URLQueryItem(name: "q", value: query))
        components.queryItems = items
        guard let finalURL = components.url else { throw APIError.invalidURL }
        let request = try await makeRequest(url: finalURL)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unexpectedResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.server(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }
        let envelope = try decoder.decode(GameSearchResponse.self, from: data)
        return envelope.games
    }

    public func fetchGame(gameId: String) async throws -> Game? {
        let url = urlWithDevice("/api/games/\(gameId)")
        let request = try await makeRequest(url: url)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unexpectedResponse
        }
        if httpResponse.statusCode == 404 { return nil }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.server(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }
        do {
            return try decoder.decode(Game.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    public func fetchGamesBatch(gameIds: [String]) async throws -> [Game] {
        let url = urlWithDevice("/api/games/batch")
        var request = try await makeRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let bodyPayload = ["gameIds": gameIds]
        request.httpBody = try? JSONSerialization.data(withJSONObject: bodyPayload)

        struct GamesBatchResponse: Decodable {
            let games: [Game]
        }

        let response: GamesBatchResponse = try await decode(request)
        return response.games
    }
}
