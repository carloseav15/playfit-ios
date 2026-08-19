import Foundation

extension HTTPPlayfitClient {
    func makeRequest(url: URL) async throws -> URLRequest {
        if let current = authSession, current.expires(within: 60) {
            let task: Task<AuthSession, Error>
            if let existing = refreshTask {
                task = existing
            } else {
                let newTask = Task { try await self.refreshSession(current) }
                refreshTask = newTask
                task = newTask
            }
            do {
                let refreshed = try await task.value
                if authSession?.refreshToken == current.refreshToken {
                    authSession = refreshed
                    refreshTask = nil
                    AuthSessionStore.save(refreshed)
                } else {
                    refreshTask = nil
                }
            } catch {
                if authSession?.refreshToken == current.refreshToken {
                    authSession = nil
                    refreshTask = nil
                    AuthSessionStore.clear()
                } else {
                    refreshTask = nil
                }
                throw error
            }
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = Self.requestTimeout
        if let token = authSession?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func refreshSession(_ current: AuthSession) async throws -> AuthSession {
        guard var components = URLComponents(
            url: PlayfitAPI.supabaseURL.appendingPathComponent("/auth/v1/token"),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token")]
        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.timeoutInterval = Self.requestTimeout
        request.httpMethod = "POST"
        request.setValue(PlayfitAPI.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(
            withJSONObject: ["refresh_token": current.refreshToken]
        )

        let (data, httpResponse) = try await requestData(for: request)
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.server(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }

        let refreshed = try decoder.decode(RefreshTokenResponse.self, from: data)
        return AuthSession(
            accessToken: refreshed.accessToken,
            refreshToken: refreshed.refreshToken,
            expiresAt: Date().addingTimeInterval(refreshed.expiresIn),
            userId: refreshed.user?.id ?? current.userId,
            email: refreshed.user?.email ?? current.email
        )
    }
}
