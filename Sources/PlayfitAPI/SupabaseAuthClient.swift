import AuthenticationServices
import Foundation
import Logging

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public enum AuthError: LocalizedError {
    case invalidURL
    case server(Int, String?)
    case unexpectedResponse
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid auth URL"
        case .server(let code, let body):
            "Auth error \(code): \(body ?? "unknown")"
        case .unexpectedResponse:
            "Unexpected auth response"
        case .cancelled:
            "Sign-in was cancelled"
        }
    }
}

@MainActor
public final class SupabaseAuthClient: NSObject {
    private let baseURL: URL
    private let anonKey: String
    private let session: URLSession
    private let logger = Logger(label: "com.playfit.auth")

    private static let requestTimeout: TimeInterval = 20

    public init(
        baseURL: URL = PlayfitAPI.supabaseURL,
        anonKey: String = PlayfitAPI.supabaseAnonKey,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.anonKey = anonKey
        self.session = session
    }

    // MARK: - Email / Password

    /// Returns nil when sign-up succeeded but the project requires email confirmation
    /// before a session can be issued.
    public func signUp(email: String, password: String) async throws -> AuthSession? {
        let request = try makeRequest(path: "/auth/v1/signup", body: ["email": email, "password": password])
        let data = try await execute(request)
        if let token = try? JSONDecoder().decode(TokenResponse.self, from: data), !token.accessToken.isEmpty {
            return token.session
        }
        return nil
    }

    /// Mirrors the web's `supabase.auth.signInAnonymously()`: GoTrue's signup endpoint
    /// issues a session for an anonymous user when no credentials are supplied.
    public func signInAnonymously() async throws -> AuthSession {
        let request = try makeRequest(path: "/auth/v1/signup", body: [:])
        let data = try await execute(request)
        let token = try JSONDecoder().decode(TokenResponse.self, from: data)
        return token.session
    }

    public func signIn(email: String, password: String) async throws -> AuthSession {
        var request = try makeRequest(path: "/auth/v1/token", body: ["email": email, "password": password])
        guard let requestURL = request.url,
              var components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false) else {
            throw AuthError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "grant_type", value: "password")]
        request.url = components.url
        let data = try await execute(request)
        let token = try JSONDecoder().decode(TokenResponse.self, from: data)
        return token.session
    }

    /// Mirrors the web's `supabase.auth.resetPasswordForEmail`: always succeeds from the
    /// caller's perspective so the UI can show a neutral message regardless of whether the
    /// email is registered. `redirect_to` points the email link back at this app so
    /// `playfit://auth-callback` reaches `PlayfitRootView`'s `.onOpenURL`.
    public func resetPasswordForEmail(_ email: String, redirectScheme: String = "playfit") async throws {
        var request = try makeRequest(path: "/auth/v1/recover", body: ["email": email])
        guard let requestURL = request.url,
              var components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false) else {
            throw AuthError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "redirect_to", value: "\(redirectScheme)://auth-callback"),
        ]
        request.url = components.url
        _ = try await execute(request)
    }

    /// Updates the password on the account owned by `accessToken`. Used both for a
    /// signed-in user changing their password and for a password-recovery session
    /// (the token from a `type=recovery` deep link) setting a new one.
    public func updatePassword(accessToken: String, newPassword: String) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("/auth/v1/user"))
        request.timeoutInterval = Self.requestTimeout
        request.httpMethod = "PUT"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["password": newPassword])
        _ = try await execute(request)
    }

    /// Parses a `playfit://auth-callback` deep link (the redirect target for both
    /// Google sign-in and password recovery emails) into its session and whether it
    /// represents a password-recovery link (`type=recovery` in the fragment/query).
    public static func parseCallbackURL(_ url: URL) throws -> (session: AuthSession, isPasswordRecovery: Bool) {
        let params = Self.callbackParams(from: url)
        let session = try Self.session(fromCallbackParams: params)
        return (session, params["type"] == "recovery")
    }

    public func signOut(accessToken: String) async {
        guard var request = try? makeRequest(path: "/auth/v1/logout", body: nil) else { return }
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        _ = try? await execute(request)
    }

    // MARK: - Google (native, via the system browser)

    public func signInWithGoogle(redirectScheme: String = "playfit") async throws -> AuthSession {
        let authorizeURL = baseURL.appendingPathComponent("/auth/v1/authorize")
        guard var components = URLComponents(url: authorizeURL, resolvingAgainstBaseURL: false) else {
            throw AuthError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "redirect_to", value: "\(redirectScheme)://auth-callback"),
        ]
        guard let finalURL = components.url else { throw AuthError.invalidURL }

        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            let webAuthSession = ASWebAuthenticationSession(
                url: finalURL,
                callbackURLScheme: redirectScheme
            ) { url, error in
                if let url {
                    continuation.resume(returning: url)
                } else if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
                    continuation.resume(throwing: AuthError.cancelled)
                } else {
                    continuation.resume(throwing: error ?? AuthError.unexpectedResponse)
                }
            }
            webAuthSession.presentationContextProvider = self
            webAuthSession.prefersEphemeralWebBrowserSession = true
            webAuthSession.start()
        }

        return try Self.parseImplicitSession(from: callbackURL)
    }

    // MARK: - Helpers

    private func makeRequest(path: String, body: [String: String]?) throws -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.timeoutInterval = Self.requestTimeout
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        return request
    }

    private func execute(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.unexpectedResponse
            }
            logger.debug("Auth request completed: \(request.httpMethod ?? "GET") \(request.url?.path ?? "unknown") - \(httpResponse.statusCode)")
            guard (200...299).contains(httpResponse.statusCode) else {
                throw AuthError.server(httpResponse.statusCode, String(data: data, encoding: .utf8))
            }
            return data
        } catch {
            logger.error("Auth request failed: \(request.httpMethod ?? "GET") \(request.url?.path ?? "unknown") - \(String(describing: error))")
            throw error
        }
    }

    /// Supabase's OAuth authorize and password-recovery redirects both return their
    /// payload in the URL's fragment (`#access_token=...`), not as a JSON body.
    private static func callbackParams(from url: URL) -> [String: String] {
        let fragment = url.fragment ?? url.query ?? ""
        return fragment
            .split(separator: "&")
            .reduce(into: [String: String]()) { dict, pair in
                let parts = pair.split(separator: "=", maxSplits: 1)
                guard parts.count == 2 else { return }
                dict[String(parts[0])] = String(parts[1]).removingPercentEncoding ?? String(parts[1])
            }
    }

    /// Does not include the user id or email directly — those are decoded from the
    /// access token JWT's own claims.
    private static func parseImplicitSession(from url: URL) throws -> AuthSession {
        try session(fromCallbackParams: callbackParams(from: url))
    }

    private static func session(fromCallbackParams params: [String: String]) throws -> AuthSession {
        if let errorDescription = params["error_description"] {
            throw AuthError.server(400, errorDescription)
        }
        guard let accessToken = params["access_token"],
              let refreshToken = params["refresh_token"],
              let expiresInString = params["expires_in"],
              let expiresIn = Double(expiresInString) else {
            throw AuthError.unexpectedResponse
        }

        let claims = decodeJWTClaims(accessToken)
        let userId = claims?["sub"] as? String ?? ""
        let email = claims?["email"] as? String

        return AuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(expiresIn),
            userId: userId,
            email: email
        )
    }

    private static func decodeJWTClaims(_ jwt: String) -> [String: Any]? {
        let parts = jwt.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }
        guard let data = Data(base64Encoded: base64) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}

extension SupabaseAuthClient: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if os(iOS)
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
        #else
        return ASPresentationAnchor()
        #endif
    }
}
