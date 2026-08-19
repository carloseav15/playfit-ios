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
            XCTAssertEqual(request.timeoutInterval, HTTPPlayfitClient.requestTimeout)
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

    func testFetchGamePropagatesNetworkFailure() async {
        URLProtocolStub.handler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            _ = try await makeClient().fetchGame(gameId: "offline")
            XCTFail("Expected the network error to propagate")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchGamesBatchSkipsEmptyRequest() async throws {
        URLProtocolStub.handler = { _ in
            XCTFail("An empty batch must not make a network request")
            return (500, Data())
        }

        let games = try await makeClient().fetchGamesBatch(gameIds: [])

        XCTAssertTrue(games.isEmpty)
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
