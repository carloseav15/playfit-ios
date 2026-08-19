import PlayfitFeatures
import Foundation
import SwiftUI

@main
struct PlayfitIOSApp: App {
    var body: some Scene {
        WindowGroup {
            PlayfitRootView()
                .environment(\.locale, Locale(identifier: "en_US"))
        }
    }
}
