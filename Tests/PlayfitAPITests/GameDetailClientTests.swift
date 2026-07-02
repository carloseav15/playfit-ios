import Foundation
@testable import PlayfitAPI
import XCTest

final class GameDetailClientTests: XCTestCase {
    override func tearDown() {
        URLProtocolStub.handler = nil
        super.tearDown()
    }

    func testFetchGameDecodesDetailByID() async throws {
        URLProtocolStub.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/games/celeste")
            let data = Data(#"{"gameId":"celeste","title":"Celeste","primaryGenre":"Platformer","tags":["precision"],"availablePlatformIds":["switch_1"],"availablePlatformNames":["Nintendo Switch"],"releaseState":"released"}"#.utf8)
            return (200, data)
        }

        let game = try await makeClient().fetchGame(gameId: "celeste")

        XCTAssertEqual(game?.id, "celeste")
        XCTAssertEqual(game?.primaryGenre, "Platformer")
        XCTAssertEqual(game?.availablePlatformNames, ["Nintendo Switch"])
    }

    func testFetchGameReturnsNilForNotFound() async throws {
        URLProtocolStub.handler = { _ in (404, Data()) }

        let game = try await makeClient().fetchGame(gameId: "missing")

        XCTAssertNil(game)
    }

    private func makeClient() -> HTTPPlayfitClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return HTTPPlayfitClient(
            baseURL: URL(string: "https://playfit.test")!,
            session: URLSession(configuration: configuration)
        )
    }
}

private final class URLProtocolStub: URLProtocol, @unchecked Sendable {
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
