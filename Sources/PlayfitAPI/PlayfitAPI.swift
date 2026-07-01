import Foundation

public enum PlayfitAPI {
    private static let environmentKey = "PlayfitAPIEnvironment"

    public enum Environment: String, CaseIterable, Identifiable {
        case development = "development"
        case production = "production"

        public var id: String { rawValue }

        public var label: String {
            switch self {
            case .development: "Development (Local)"
            case .production: "Production (Vercel)"
            }
        }

        public var url: URL {
            switch self {
            case .development:
                return URL(string: "http://127.0.0.1:3000")!
            case .production:
                return URL(string: "https://playfit-gold.vercel.app")!
            }
        }

        /// The Supabase project URL used for Auth (sign up/in, OAuth authorize). This is a
        /// different service than `url` above (which points at the Next.js API).
        public var supabaseURL: URL {
            switch self {
            case .development:
                return URL(string: "http://127.0.0.1:54321")!
            case .production:
                // TODO: production Supabase project URL not yet available to this app.
                // Auth will fail fast with an invalidURL error until this is set.
                return URL(string: "https://playfit-production-supabase.invalid")!
            }
        }

        /// Supabase's publishable/anon key. Safe to embed in client code by design
        /// (same value the web app exposes as NEXT_PUBLIC_SUPABASE_ANON_KEY).
        public var supabaseAnonKey: String {
            switch self {
            case .development:
                return "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH"
            case .production:
                // TODO: production anon/publishable key not yet available to this app.
                return ""
            }
        }
    }

    public static var activeEnvironment: Environment {
        get {
            #if DEBUG
            if let saved = UserDefaults.standard.string(forKey: environmentKey),
               let env = Environment(rawValue: saved) {
                return env
            }
            return .development
            #else
            return .production
            #endif
        }
        set {
            #if DEBUG
            UserDefaults.standard.set(newValue.rawValue, forKey: environmentKey)
            #endif
        }
    }

    public static var `default`: URL {
        activeEnvironment.url
    }

    public static var supabaseURL: URL {
        activeEnvironment.supabaseURL
    }

    public static var supabaseAnonKey: String {
        activeEnvironment.supabaseAnonKey
    }
}
