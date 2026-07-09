import PlayfitAPI
import PlayfitDesignSystem
import PlayfitModels
import PlayfitStorage
import Foundation
import SwiftUI

public struct PlayfitRootView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(StorageKeys.appearanceMode) private var appearanceMode: AppearanceMode = .system
    @AppStorage(StorageKeys.authEmail) private var authEmail: String = ""
    @State private var viewModel: PlayViewModel
    @State private var showOnboarding = false
    @State private var showSignInSheet = false
    @State private var isReady = false
    @SceneStorage("selectedTab") private var selectedTab: Int = 0
    @State private var showSplash = !ProcessInfo.processInfo.arguments.contains {
        $0.hasPrefix("-playfit-ui-testing")
    }

    public init() {
        self._viewModel = State(initialValue: PlayViewModel(apiClient: HTTPPlayfitClient()))
    }

    public var body: some View {
        ZStack {
            mainContent

            if showSplash {
                SplashView {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .preferredColorScheme(appearanceMode.colorScheme)
        .sensoryFeedback(.success, trigger: viewModel.pickIds.count)
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.excludedIds.count)
        .sensoryFeedback(.success, trigger: viewModel.onboardingCompleted)
    }

    private var mainContent: some View {
        Group {
            if !isReady {
                startupLoading
            } else if viewModel.onboardingCompleted,
                      viewModel.pool.isEmpty,
                      let error = viewModel.error {
                startupError(error)
            } else {
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
                    .sheet(isPresented: $showSignInSheet, onDismiss: {
                        // A successful sign-in from the landing screen has nowhere
                        // else to go: if the account has no completed onboarding on
                        // the server, route into onboarding instead of leaving the
                        // user stuck looking at the same landing screen.
                        if viewModel.authSession != nil && !viewModel.onboardingCompleted {
                            viewModel.onboardingStarted = true
                            showOnboarding = true
                        }
                    }) {
                        SignInSheetView(authEmail: $authEmail)
                            .environment(\.playViewModel, viewModel)
                    }
                }
            }
        }
        .tint(.playfitAccent)
        .transaction { transaction in
            if reduceMotion {
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
        }
        .accessibilityIdentifier("playfit.root")
        .statusToast(message: $viewModel.toastMessage, token: $viewModel.toastToken, style: viewModel.toastStyle)
        .onOpenURL { url in
            viewModel.handleAuthCallback(url: url)
        }
        .sheet(isPresented: Binding(
            get: { viewModel.pendingPasswordRecovery != nil },
            set: { isPresented in
                if !isPresented { viewModel.dismissPasswordRecovery() }
            }
        )) {
            ResetPasswordView()
                .environment(\.playViewModel, viewModel)
        }
        .task {
            // Deterministic, offline states for UI tests: "-seeded" reaches the main
            // tab bar (with an empty pool/picks) without a network round-trip; plain
            // "-playfit-ui-testing" reaches the intro screen the same way.
            if ProcessInfo.processInfo.arguments.contains("-playfit-ui-testing-seeded") {
                viewModel.onboardingCompleted = true
                isReady = true
                return
            }
            if ProcessInfo.processInfo.arguments.contains("-playfit-ui-testing") {
                isReady = true
                return
            }
            await viewModel.load()
            showOnboarding = viewModel.onboardingStarted && !viewModel.onboardingCompleted
            isReady = true
        }
    }

    private var startupLoading: some View {
        ZStack {
            Color.playfitBackground.ignoresSafeArea()
            VStack(spacing: PlayfitSpacing.sm) {
                ProgressView().controlSize(.large).tint(.playfitAccent)
                    .accessibilityIdentifier("playfit.startup.loading")
                Text("Loading Playfit…").font(.headline)
                Text("Restoring your profile and recommendations.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .preferredColorScheme(appearanceMode.colorScheme)
    }

    private func startupError(_ message: String) -> some View {
        ZStack {
            Color.playfitBackground.ignoresSafeArea()
            ContentUnavailableView {
                Label("Playfit could not sync", systemImage: "icloud.slash")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") { Task { await viewModel.syncIfOnline() } }
                    .buttonStyle(.borderedProminent)
                Button("Use Local Data") { viewModel.clearError() }
                    .buttonStyle(.bordered)
            }
            .accessibilityIdentifier("playfit.startup.error")
        }
        .preferredColorScheme(appearanceMode.colorScheme)
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label("Play Next", systemImage: "safari")
            }
            .tag(0)

            NavigationStack {
                PicksView()
            }
            .tabItem {
                Label("Picks", systemImage: "bookmark")
            }
            .badge(viewModel.picks.count)
            .tag(1)

            NavigationStack {
                TasteView()
            }
            .tabItem {
                Label("Taste", systemImage: "slider.horizontal.3")
            }
            .tag(2)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(3)
        }
        .accessibilityIdentifier("playfit.main.tabs")
        .safeAreaInset(edge: .top, spacing: 0) {
            syncStatusBar
        }
        .environment(\.playViewModel, viewModel)
        .preferredColorScheme(appearanceMode.colorScheme)
    }

    @ViewBuilder
    private var syncStatusBar: some View {
        if viewModel.syncState == .syncing {
            Label("Syncing changes…", systemImage: "icloud.and.arrow.up")
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(.regularMaterial)
        } else if viewModel.syncState == .failed || viewModel.pendingActionsCount > 0 {
            HStack(spacing: PlayfitSpacing.sm) {
                Label("Changes waiting to sync", systemImage: "exclamationmark.icloud")
                    .font(.caption.weight(.semibold))
                Spacer()
                Button("Retry") { Task { await viewModel.syncIfOnline() } }
                    .font(.caption.bold())
            }
            .padding(.horizontal, PlayfitSpacing.md)
            .padding(.vertical, 7)
            .background(.orange.opacity(0.14))
        }
    }
}
