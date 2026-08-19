import Foundation
import PlayfitModels

extension HTTPPlayfitClient {
    public func fetchPlayNext() async throws -> PlayNextModel {
        let url = urlWithDevice("/api/recommendations/today")
        var request = try await makeRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, httpResponse) = try await requestData(for: request)
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
        let request = try await makeRequest(url: url)
        return try await decode(request)
    }
}
