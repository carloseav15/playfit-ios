import Foundation
import Logging

public actor HTTPPlayfitClient: PlayfitAPIClient {
    let baseURL: URL
    let session: URLSession
    let deviceID: String
    let decoder: JSONDecoder
    let encoder: JSONEncoder
    let logger = Logger(label: "com.playfit.api")
    var authSession: AuthSession?
    var refreshTask: Task<AuthSession, Error>?

    static let requestTimeout: TimeInterval = 20

    public init(baseURL: URL = PlayfitAPI.default, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.deviceID = DeviceID.loadOrCreate()
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    nonisolated public func setAuthSession(_ session: AuthSession?) {
        Task {
            await self.updateAuthSession(session)
        }
    }

    private func updateAuthSession(_ session: AuthSession?) {
        self.authSession = session
        self.refreshTask = nil
    }
}
