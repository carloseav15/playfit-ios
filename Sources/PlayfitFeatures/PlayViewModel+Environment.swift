import SwiftUI

private struct PlayViewModelKey: EnvironmentKey {
    static var defaultValue: PlayViewModel {
        MainActor.assumeIsolated {
            PlayViewModel()
        }
    }
}

extension EnvironmentValues {
    @MainActor public var playViewModel: PlayViewModel {
        get { self[PlayViewModelKey.self] }
        set { self[PlayViewModelKey.self] = newValue }
    }
}
