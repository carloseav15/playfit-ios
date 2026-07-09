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

    func testResetPasswordForEmailIncludesRedirectToTheAppCallback() async throws {
        AuthURLProtocolStub.handler = { request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                XCTFail("Request had no URL")
                return (200, Data("{}".utf8))
            }
            var redirectTo: String?
            for item in components.queryItems ?? [] where item.name == "redirect_to" {
                redirectTo = item.value
            }
            XCTAssertEqual(redirectTo, "playfit://auth-callback")
            return (200, Data("{}".utf8))
        }

        try await makeClient().resetPasswordForEmail("player@example.com")
    }

    func testUpdatePasswordPutsToUserEndpoint() async throws {
        AuthURLProtocolStub.handler = { request in
            XCTAssertEqual(request.url?.path, "/auth/v1/user")
            XCTAssertEqual(request.httpMethod, "PUT")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer recovery-token")
            let body = try XCTUnwrap(request.httpBodyData())
            let payload = try JSONDecoder().decode([String: String].self, from: body)
            XCTAssertEqual(payload["password"], "new-password-123")
            return (200, Data("{}".utf8))
        }

        try await makeClient().updatePassword(accessToken: "recovery-token", newPassword: "new-password-123")
    }

    func testParseCallbackURLDetectsPasswordRecovery() throws {
        let url = try XCTUnwrap(URL(
            string: "playfit://auth-callback#access_token=\(Self.sampleJWT)&refresh_token=refresh-1&expires_in=3600&type=recovery"
        ))

        let result = try SupabaseAuthClient.parseCallbackURL(url)

        XCTAssertTrue(result.isPasswordRecovery)
        XCTAssertEqual(result.session.accessToken, Self.sampleJWT)
        XCTAssertEqual(result.session.refreshToken, "refresh-1")
    }

    func testParseCallbackURLDoesNotFlagOrdinarySignIn() throws {
        let url = try XCTUnwrap(URL(
            string: "playfit://auth-callback#access_token=\(Self.sampleJWT)&refresh_token=refresh-1&expires_in=3600"
        ))

        let result = try SupabaseAuthClient.parseCallbackURL(url)

        XCTAssertFalse(result.isPasswordRecovery)
    }

    /// A minimal unsigned JWT with `{"sub":"user-1","email":"player@example.com"}` as its payload,
    /// enough for `parseCallbackURL`'s claims decoding (it never verifies the signature).
    private static let sampleJWT =
        "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VyLTEiLCJlbWFpbCI6InBsYXllckBleGFtcGxlLmNvbSJ9.sig"

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
