import Foundation

public enum DeviceID {
    private static let key = "com.playfit.deviceID"

    public static func loadOrCreate() -> String {
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let new = UUID().uuidString.lowercased()
        UserDefaults.standard.set(new, forKey: key)
        return new
    }
}
