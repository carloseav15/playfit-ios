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

        // NOTE: 127.0.0.1 only reaches the Mac itself — it works from the Simulator
        // (shares the Mac's network stack) but not from a physical device. Using the
        // Mac's LAN IP instead lets a real iPhone on the same WiFi reach local dev.
        // Update this if your Mac's IP changes (`ipconfig getifaddr en0`).
        private static let localDevHost = "192.168.1.153"

        public var url: URL {
            switch self {
            case .development:
                return URL(string: "http://\(Self.localDevHost):3000")!
            case .production:
                return URL(string: "https://playfit-gold.vercel.app")!
            }
        }

        /// The Supabase project URL used for Auth (sign up/in, OAuth authorize). This is a
        /// different service than `url` above (which points at the Next.js API).
        public var supabaseURL: URL {
            switch self {
            case .development:
                return URL(string: "http://\(Self.localDevHost):54321")!
            case .production:
                return URL(string: "https://vhhnwjuwqbspvllvppnn.supabase.co")!
            }
        }

        /// Supabase's publishable/anon key. Safe to embed in client code by design
        /// (same value the web app exposes as NEXT_PUBLIC_SUPABASE_ANON_KEY).
        public var supabaseAnonKey: String {
            switch self {
            case .development:
                return "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH"
            case .production:
                return "sb_publishable_In29cjV8e5T_obAhkwTZkw_ndu8R_ch"
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
            return .production
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
