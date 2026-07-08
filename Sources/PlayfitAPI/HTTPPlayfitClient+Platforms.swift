import Foundation
import PlayfitModels

extension HTTPPlayfitClient {
    public func fetchPlatforms() async throws -> [Platform] {
        let url = urlWithDevice("/api/platforms")
        let request = try await makeRequest(url: url)
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
}
