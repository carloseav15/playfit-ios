import Foundation

extension HTTPPlayfitClient {
    func urlWithDevice(_ path: String) -> URL {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        else { return baseURL.appendingPathComponent(path) }
        components.queryItems = [URLQueryItem(name: "device_id", value: deviceID)]
        return components.url ?? baseURL.appendingPathComponent(path)
    }

    func requestData(for request: URLRequest) async throws -> (data: Data, response: HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unexpectedResponse
            }
            logger.debug("Request completed: \(request.httpMethod ?? "GET") \(request.url?.path ?? "unknown") - \(httpResponse.statusCode)")
            return (data, httpResponse)
        } catch {
            logger.error("Request failed: \(request.httpMethod ?? "GET") \(request.url?.path ?? "unknown") - \(String(describing: error))")
            throw error
        }
    }

    func decode<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, httpResponse) = try await requestData(for: request)
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
