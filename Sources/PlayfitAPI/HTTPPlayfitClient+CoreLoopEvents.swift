import Foundation

extension HTTPPlayfitClient {
    public func recordCoreLoopEvent(_ event: CoreLoopClientEvent) async throws {
        let url = urlWithDevice("/api/core-loop-events")
        var request = try await makeRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(event)
        let (_, response) = try await requestData(for: request)
        guard (200...299).contains(response.statusCode) else {
            throw APIError.server(response.statusCode, "Core-loop event was rejected")
        }
    }
}
