import Foundation

extension HTTPPlayfitClient {
    func urlWithDevice(_ path: String) -> URL {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        else { return baseURL.appendingPathComponent(path) }
        components.queryItems = [URLQueryItem(name: "device_id", value: deviceID)]
        return components.url ?? baseURL.appendingPathComponent(path)
    }

    func decode<T: Decodable>(_ request: URLRequest) async throws -> T {
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
