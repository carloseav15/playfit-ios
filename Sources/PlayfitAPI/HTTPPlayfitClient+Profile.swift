import Foundation
import PlayfitModels

extension HTTPPlayfitClient {
    public func fetchProfile() async throws -> UserProfile? {
        let url = urlWithDevice("/api/profile")
        let request = try await makeRequest(url: url)
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
        let request = try await makeRequest(url: url)
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

    public func fetchOnboardingCompletedAt() async throws -> String? {
        let url = urlWithDevice("/api/profile")
        let request = try await makeRequest(url: url)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unexpectedResponse
        }
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 { return nil }
            throw APIError.server(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }
        let envelope = try decoder.decode(ProfileEnvelope.self, from: data)
        return envelope.state?.onboarding?.onboardingCompletedAt
    }

    public func saveGameState(gameId: String, state: UserGameState) async throws {
        let url = urlWithDevice("/api/profile/games/\(gameId)")
        var request = try await makeRequest(url: url)
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
        var request = try await makeRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(ProfileSaveRequestMapper.makeBody(
            deviceID: deviceID,
            profile: profile,
            gameStates: gameStates,
            onboarding: onboarding
        ))

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unexpectedResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.server(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }
    }

    public func deleteProfile() async throws {
        let url = urlWithDevice("/api/profile")
        var request = try await makeRequest(url: url)
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
        var request = try await makeRequest(url: url)
        request.httpMethod = "DELETE"
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unexpectedResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.server(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }
    }
}
