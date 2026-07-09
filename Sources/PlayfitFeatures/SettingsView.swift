import PlayfitAPI
import PlayfitDesignSystem
import PlayfitModels
import PlayfitStorage
import SwiftUI

public struct SettingsView: View {
    @AppStorage(StorageKeys.appearanceMode) private var appearanceMode: AppearanceMode = .system
    @AppStorage(StorageKeys.authEmail) private var authEmail: String = ""
    @Environment(\.playViewModel) private var viewModel
    @State private var showSignInSheet = false

    public init() {}

    public var body: some View {
        ZStack {
            Color.playfitBackground.ignoresSafeArea()
            
            List {
            Section {
                NavigationLink {
                    AppearanceView(appearanceMode: $appearanceMode)
                } label: {
                    HStack(spacing: PlayfitSpacing.md) {
                        Image(systemName: appearanceModeIcon)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("App Appearance")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.primary)
                            Text("Theme: \(appearanceMode.label)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .accessibilityLabel("App Appearance, Theme: \(appearanceMode.label)")

                NavigationLink {
                    PlatformSelectionView()
                } label: {
                    HStack(spacing: PlayfitSpacing.md) {
                        Image(systemName: "gamecontroller")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Your Platforms")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.primary)
                            Text("\(viewModel.selectedPlatformIds.count) system\(viewModel.selectedPlatformIds.count == 1 ? "" : "s") selected")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .accessibilityLabel("Your Platforms, \(viewModel.selectedPlatformIds.count) systems selected")

                NavigationLink {
                    PrivacySettingsView()
                } label: {
                    HStack(spacing: PlayfitSpacing.md) {
                        Image(systemName: "exclamationmark.shield")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Data & Privacy")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.primary)
                            Text("Manage your personal data, local taste storage, and account settings.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .accessibilityLabel("Data and Privacy Settings")
            } header: {
                Text("General")
                    .textCase(.uppercase)
            }

            Section {
                if authEmail.isEmpty {
                    HStack(spacing: PlayfitSpacing.md) {
                        Image(systemName: "icloud")
                            .font(.subheadline)
                            .foregroundColor(Color.playfitAccent)
                            .frame(width: 36, height: 36)
                            .background(Color.playfitAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.playfitAccent.opacity(0.24), lineWidth: 1)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cloud Synchronization")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.primary)
                            Text("Local Profile Only")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your library is saved locally in this app.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            showSignInSheet = true
                        } label: {
                            Text("Sign In / Sync")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.playfitAccent, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Sign In or Synchronize")
                        .padding(.top, 4)
                    }
                } else {
                    HStack(spacing: PlayfitSpacing.md) {
                        Image(systemName: "icloud.and.arrow.up.fill")
                            .font(.subheadline)
                            .foregroundColor(.playfitPositive)
                            .frame(width: 36, height: 36)
                            .background(Color.playfitPositive.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.playfitPositive.opacity(0.24), lineWidth: 1)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cloud Synchronized")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.primary)
                            Text("Signed in as: \(authEmail)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your profile preferences are synced to the cloud.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            authEmail = ""
                            Task { await viewModel.signOut() }
                        } label: {
                            Text("Sign Out")
                                .font(.caption.bold())
                                .foregroundColor(.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Sign Out")
                        .padding(.top, 4)
                    }
                }
            } header: {
                Text("Account")
                    .textCase(.uppercase)
            }


            #if DEBUG
            Section {
                NavigationLink {
                    DeveloperSettingsView()
                } label: {
                    HStack(spacing: PlayfitSpacing.md) {
                        Image(systemName: "curlybraces")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Developer Settings")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.primary)
                            Text("Env: \(PlayfitAPI.activeEnvironment.label)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .accessibilityLabel("Developer Settings, Environment: \(PlayfitAPI.activeEnvironment.label)")
            } header: {
                Text("Developer")
                    .textCase(.uppercase)
            }
            #endif

            Section {
                HStack(spacing: PlayfitSpacing.md) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.secondary)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                    Text("Playfit for iOS")
                        .font(.subheadline.weight(.semibold))
                }

                HStack(spacing: PlayfitSpacing.md) {
                    Image(systemName: "swift")
                        .foregroundColor(.orange)
                        .frame(width: 36, height: 36)
                        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.orange.opacity(0.24), lineWidth: 1)
                        )
                    Text("Built with SwiftUI")
                        .font(.subheadline.weight(.semibold))
                }
            } header: {
                Text("About")
                    .textCase(.uppercase)
            }
        }
        .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showSignInSheet) {
            SignInSheetView(authEmail: $authEmail)
        }
    }


    private var appearanceModeIcon: String {
        switch appearanceMode {
        case .light: "sun.max"
        case .dark: "moon"
        case .system: "circle.lefthalf.striped.horizontal"
        }
    }
}
