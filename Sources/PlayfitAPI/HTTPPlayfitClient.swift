import Foundation
import PlayfitModels

public final class HTTPPlayfitClient: PlayfitAPIClient, @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let deviceID: String
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var authSession: AuthSession?

    public init(baseURL: URL = PlayfitAPI.default) {
        self.baseURL = baseURL
        self.session = URLSession.shared
        self.deviceID = DeviceID.loadOrCreate()
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    public func setAuthSession(_ session: AuthSession?) {
        self.authSession = session
    }

    // MARK: - PlayfitAPIClient

    public func fetchPlayNext() async throws -> PlayNextModel {
        let url = urlWithDevice("/api/recommendations/today")
        var request = makeRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unexpectedResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.server(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           json["needsResync"] as? Bool == true {
            throw APIError.server(200, "needsResync")
        }
        do {
            return try decoder.decode(PlayNextModel.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    public func fetchPicks() async throws -> [RankedRecommendation] {
        let url = urlWithDevice("/api/recommendations/picks")
        var request = makeRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await decode(request)
    }

    public func searchGames(query: String) async throws -> [Game] {
        let url = urlWithDevice("/api/games")
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        var items = components.queryItems ?? []
        items.append(URLQueryItem(name: "q", value: query))
        components.queryItems = items
        guard let finalURL = components.url else { throw APIError.invalidURL }
        let request = makeRequest(url: finalURL)
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

    public func fetchProfile() async throws -> UserProfile? {
        let url = urlWithDevice("/api/profile")
        let request = makeRequest(url: url)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unexpectedResponse
        }
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 { return nil }
            throw APIError.server(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }
        let envelope = try decoder.decode(ProfileEnvelope.self, from: data)
        return envelope.state?.profile
    }

    public func fetchGameStates() async throws -> [String: UserGameState] {
        let url = urlWithDevice("/api/profile")
        let request = makeRequest(url: url)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unexpectedResponse
        }
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 { return [:] }
            throw APIError.server(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }
        let envelope = try decoder.decode(ProfileEnvelope.self, from: data)
        return envelope.state?.gameStates ?? [:]
    }

    public func saveGameState(gameId: String, state: UserGameState) async throws {
        let url = urlWithDevice("/api/profile/games/\(gameId)")
        var request = makeRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(state)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unexpectedResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.server(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }
    }

    public func saveProfile(profile: UserProfile, gameStates: [String: UserGameState], onboarding: OnboardingPayload) async throws {
        let url = urlWithDevice("/api/profile")
        var request = makeRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let now = ISO8601DateFormatter().string(from: Date())

        // Build gameStates dict matching productGameStateSchema
        var gsDict: [String: Any] = [:]
        for (gameId, state) in gameStates {
            var entry: [String: Any] = [
                "gameId": gameId,
                "title": "",
                "inBacklog": state.inBacklog,
                "inWishlist": state.inWishlist,
                "inPlayfitPicks": state.inPlayfitPicks,
                "source": state.source.isEmpty ? "manual" : state.source,
                "createdAt": state.createdAt.isEmpty ? now : state.createdAt,
                "updatedAt": state.updatedAt.isEmpty ? now : state.updatedAt,
            ]
            if let rating = state.rating {
                entry["rating"] = rating
            }
            if let status = state.status {
                entry["status"] = status.rawValue
            }
            if state.excluded {
                entry["excluded"] = true
            }
            gsDict[gameId] = entry
        }

        // Build onboarding matching persistedOnboardingSchema
        let platformObjects = onboarding.platforms.map { pid in
            ["platformId": pid, "status": "available"] as [String: String]
        }
        let onboardingDict: [String: Any] = [
            "step": onboarding.step,
            "platforms": platformObjects,
            "likedGameIds": onboarding.likedGameIds,
            "dislikedGameIds": onboarding.dislikedGameIds,
            "onboardingCompletedAt": onboarding.onboardingCompletedAt as Any,
        ]

        // Build profile matching productProfileSchema
        let profileDict: [String: Any] = [
            "summary": profile.summary,
            "likedGenres": profile.likedGenres,
            "avoidedGenres": profile.avoidedGenres,
            "likedTags": profile.likedTags,
            "dislikedTags": profile.dislikedTags,
            "ratedCount": profile.ratedCount,
            "signals": profile.signals.map { s in
                ["id": s.id, "tone": s.tone.rawValue, "label": s.label, "reason": s.reason] as [String: String]
            },
        ]

        let body: [String: Any] = [
            "deviceId": deviceID,
            "gameStates": gsDict,
            "profile": profileDict,
            "onboarding": onboardingDict,
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unexpectedResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.server(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }
    }

    public func fetchPlatforms() async throws -> [Platform] {
        let url = urlWithDevice("/api/platforms")
        let request = makeRequest(url: url)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unexpectedResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.server(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }
        let envelope = try decoder.decode(PlatformsResponse.self, from: data)
        return envelope.platforms
    }

    public func deleteProfile() async throws {
        let url = urlWithDevice("/api/profile")
        var request = makeRequest(url: url)
        request.httpMethod = "DELETE"
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unexpectedResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.server(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }
    }

    public func deleteGameState(gameId: String) async throws {
        let url = urlWithDevice("/api/profile/games/\(gameId)")
        var request = makeRequest(url: url)
        request.httpMethod = "DELETE"
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unexpectedResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.server(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }
    }

    public func fetchGamesBatch(gameIds: [String]) async throws -> [Game] {
        let url = urlWithDevice("/api/games/batch")
        var request = makeRequest(url: url)
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

    // MARK: - Helpers

    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        if let token = authSession?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func urlWithDevice(_ path: String) -> URL {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        else { return baseURL.appendingPathComponent(path) }
        components.queryItems = [URLQueryItem(name: "device_id", value: deviceID)]
        return components.url ?? baseURL.appendingPathComponent(path)
    }

    private func decode<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unexpectedResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.server(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}

// MARK: - Request/Response Types

private struct ProfileState: Codable {
    let gameStates: [String: UserGameState]?
    let profile: UserProfile?
}

private struct ProfileEnvelope: Codable {
    let state: ProfileState?
}

private struct GameSearchResponse: Codable {
    let games: [Game]
}

private struct ProfileSaveBody: Codable {
    let deviceId: String?
    let gameStates: [String: UserGameState]
    let profile: UserProfile?
    let onboarding: OnboardingPayload

    enum CodingKeys: String, CodingKey {
        case deviceId
        case gameStates
        case profile
        case onboarding
    }
}

private struct PlatformsResponse: Codable {
    let platforms: [Platform]
}
