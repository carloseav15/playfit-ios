import Foundation
import PlayfitModels

extension HTTPPlayfitClient {
    public func submitCanonicalDecision(
        _ command: CanonicalDecisionCommand
    ) async throws -> CanonicalDecisionResponse {
        let url = urlWithDevice("/api/decisions")
        var request = try await makeRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(command)

        let (data, response) = try await requestData(for: request)
        if response.statusCode == 409 {
            let conflict = try? decoder.decode(CanonicalConflictResponse.self, from: data)
            throw APIError.canonicalConflict(
                currentStateVersion: conflict?.currentStateVersion,
                undoUnavailable: conflict?.undoUnavailable == true
            )
        }
        guard (200...299).contains(response.statusCode) else {
            throw APIError.server(response.statusCode, String(data: data, encoding: .utf8))
        }

        do {
            return try decoder.decode(CanonicalDecisionResponse.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    public func fetchAuthoritativeSnapshot() async throws -> AuthoritativeSnapshot {
        let url = urlWithDevice("/api/profile")
        let request = try await makeRequest(url: url)
        let (data, response) = try await requestData(for: request)
        guard (200...299).contains(response.statusCode) else {
            throw APIError.server(response.statusCode, String(data: data, encoding: .utf8))
        }

        let envelope: ProfileEnvelope
        do {
            envelope = try decoder.decode(ProfileEnvelope.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
        guard let state = envelope.state,
              let profile = state.profile,
              let persistedOnboarding = state.onboarding,
              let stateVersion = state.stateVersion else {
            throw APIError.server(200, "needsResync")
        }

        let recommendationModel = try await fetchPlayNext()
        guard recommendationModel.stateVersion == stateVersion,
              recommendationModel.rankingMetadata.profileStateVersion == stateVersion else {
            throw APIError.invalidCanonicalSnapshot("profile and ranking versions differ")
        }

        let onboarding = CanonicalOnboardingState(
            step: persistedOnboarding.step ?? "platforms",
            platforms: persistedOnboarding.platforms ?? [],
            likedGameIds: persistedOnboarding.likedGameIds ?? [],
            dislikedGameIds: persistedOnboarding.dislikedGameIds ?? []
        )
        return AuthoritativeSnapshot(
            stateVersion: stateVersion,
            profile: profile,
            gameStates: state.gameStates ?? [:],
            recommendationModel: recommendationModel,
            onboarding: onboarding,
            onboardingCompletedAt: persistedOnboarding.onboardingCompletedAt,
            lastUpdatedAt: state.updatedAt ?? state.createdAt
        )
    }
}
