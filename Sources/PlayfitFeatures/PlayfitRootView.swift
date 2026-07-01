import PlayfitAPI
import PlayfitDesignSystem
import PlayfitModels
import PlayfitStorage
import SwiftUI

public struct PlayfitRootView: View {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("authEmail") private var authEmail: String = ""
    @State private var viewModel: PlayViewModel
    @State private var showOnboarding = false
    @State private var showSignInSheet = false
    @State private var isReady = false

    public init() {
        self._viewModel = State(initialValue: PlayViewModel(apiClient: HTTPPlayfitClient()))
    }

    public var body: some View {
        Group {
            if isReady {
                if viewModel.onboardingCompleted {
                    mainTabView
                } else if showOnboarding {
                    OnboardingView(
                        onComplete: {
                            Task { await viewModel.syncIfOnline() }
                        },
                        onCancel: {
                            viewModel.onboardingStarted = false
                            showOnboarding = false
                        }
                    )
                    .environment(\.playViewModel, viewModel)
                    .preferredColorScheme(appearanceMode.colorScheme)
                } else {
                    DecisionIntroView(
                        onStart: {
                            viewModel.onboardingStarted = true
                            showOnboarding = true
                        },
                        onSignIn: {
                            showSignInSheet = true
                        }
                    )
                    .environment(\.playViewModel, viewModel)
                    .preferredColorScheme(appearanceMode.colorScheme)
                    .sheet(isPresented: $showSignInSheet) {
                        SignInSheetView(authEmail: $authEmail)
                            .environment(\.playViewModel, viewModel)
                    }
                }
            }
        }
        .statusToast(message: $viewModel.toastMessage, style: viewModel.toastStyle)
        .task {
            await viewModel.load()
            showOnboarding = viewModel.onboardingStarted && !viewModel.onboardingCompleted
            isReady = true
        }
    }

    private var mainTabView: some View {
        TabView {
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label("Play Next", systemImage: "sparkles")
            }

            NavigationStack {
                PicksView()
            }
            .tabItem {
                Label("Picks", systemImage: "bookmark")
            }
            .badge(viewModel.picks.count)

            NavigationStack {
                TasteView()
            }
            .tabItem {
                Label("Taste", systemImage: "chart.bar")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .environment(\.playViewModel, viewModel)
        .preferredColorScheme(appearanceMode.colorScheme)
    }
}
