import Foundation
@testable import PlayfitAPI
import XCTest

@MainActor
final class SupabaseAuthClientTests: XCTestCase {
    override func tearDown() {
        AuthURLProtocolStub.handler = nil
        super.tearDown()
    }

    func testResetPasswordForEmailPostsToRecoverEndpoint() async throws {
        AuthURLProtocolStub.handler = { request in
            XCTAssertEqual(request.url?.path, "/auth/v1/recover")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "test-anon-key")
            let body = try XCTUnwrap(request.httpBodyData())
            let payload = try JSONDecoder().decode([String: String].self, from: body)
            XCTAssertEqual(payload["email"], "player@example.com")
            return (200, Data("{}".utf8))
        }

        try await makeClient().resetPasswordForEmail("player@example.com")
    }

    func testResetPasswordForEmailThrowsOnServerError() async {
        AuthURLProtocolStub.handler = { _ in (400, Data(#"{"msg":"Invalid email"}"#.utf8)) }

        do {
            try await makeClient().resetPasswordForEmail("not-an-email")
            XCTFail("Expected resetPasswordForEmail to throw on a server error response")
        } catch let AuthError.server(code, _) {
            XCTAssertEqual(code, 400)
        } catch {
            XCTFail("Expected AuthError.server, got \(error)")
        }
    }

    private func makeClient() -> SupabaseAuthClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AuthURLProtocolStub.self]
        return SupabaseAuthClient(
            baseURL: URL(string: "https://playfit.test")!,
            anonKey: "test-anon-key",
            session: URLSession(configuration: configuration)
        )
    }
}

private final class AuthURLProtocolStub: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (Int, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            guard let handler = Self.handler else { throw URLError(.badServerResponse) }
            let (status, data) = try handler(request)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: status,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private extension URLRequest {
    func httpBodyData() -> Data? {
        httpBody ?? httpBodyStream.map { stream in
            stream.open()
            defer { stream.close() }
            var data = Data()
            let bufferSize = 1024
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            while stream.hasBytesAvailable {
                let read = stream.read(&buffer, maxLength: bufferSize)
                if read > 0 { data.append(buffer, count: read) }
            }
            return data
        }
    }
}
