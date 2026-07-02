import PlayfitAPI
import PlayfitDesignSystem
import PlayfitModels
import PlayfitStorage
import SwiftUI

public struct SettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("authEmail") private var authEmail: String = ""
    @Environment(\.playViewModel) private var viewModel
    @State private var showSignInSheet = false

    public init() {}

    public var body: some View {
        ZStack {
            Color.playfitBackground.ignoresSafeArea()
            
            glowBackground
            
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
                                .padding(.vertical, 8)
                                .background(Color.playfitAccent, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                } else {
                    HStack(spacing: PlayfitSpacing.md) {
                        Image(systemName: "icloud.and.arrow.up.fill")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .frame(width: 36, height: 36)
                            .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.green.opacity(0.24), lineWidth: 1)
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
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
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

    private var glowBackground: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(Color.playfitAccent.opacity(0.12))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .position(x: geometry.size.width - 50, y: 100)
                
                Circle()
                    .fill(Color.playfitToneAccent.opacity(0.08))
                    .frame(width: 280, height: 280)
                    .blur(radius: 70)
                    .position(x: 50, y: geometry.size.height - 150)
            }
            .ignoresSafeArea()
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

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable, Identifiable {
    case light, dark, system

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light: "Light"
        case .dark: "Dark"
        case .system: "System"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }
}

// MARK: - Appearance View

private struct AppearanceView: View {
    @Binding var appearanceMode: AppearanceMode

    var body: some View {
        ZStack {
            Color.playfitBackground.ignoresSafeArea()
            
            glowBackground
            
            ScrollView {
                VStack(alignment: .leading, spacing: PlayfitSpacing.md) {
                    Text("Choose your preferred theme for the interface.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                    
                    PlayfitGlassCard {
                        HStack(spacing: PlayfitSpacing.sm) {
                            ForEach(AppearanceMode.allCases) { mode in
                                Button {
                                    withAnimation {
                                        appearanceMode = mode
                                    }
                                } label: {
                                    VStack(spacing: PlayfitSpacing.xs) {
                                        Image(systemName: iconForMode(mode))
                                            .font(.title2)
                                            .foregroundStyle(appearanceMode == mode ? .white : .secondary)
                                            .frame(width: 44, height: 44)
                                            .background(
                                                appearanceMode == mode ? Color.playfitAccent : Color.primary.opacity(0.04),
                                                in: RoundedRectangle(cornerRadius: 10)
                                            )
                                        
                                        Text(mode.label)
                                            .font(.caption.bold())
                                            .foregroundStyle(appearanceMode == mode ? .primary : .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        appearanceMode == mode ? Color.primary.opacity(0.04) : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 14)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(4)
                    }
                }
                .padding(PlayfitSpacing.md)
            }
        }
        .navigationTitle("App Appearance")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func iconForMode(_ mode: AppearanceMode) -> String {
        switch mode {
        case .light: "sun.max"
        case .dark: "moon"
        case .system: "laptopcomputer"
        }
    }

    private var glowBackground: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(Color.playfitAccent.opacity(0.12))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .position(x: geometry.size.width - 50, y: 100)
                
                Circle()
                    .fill(Color.playfitToneAccent.opacity(0.08))
                    .frame(width: 280, height: 280)
                    .blur(radius: 70)
                    .position(x: 50, y: geometry.size.height - 150)
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Platform Selection

struct PlatformSelectionView: View {
    @Environment(\.playViewModel) private var viewModel
    @State private var selectedFamily: String = "nintendo"

    private let platformPresets: [PlatformPreset] = [
        PlatformPreset(id: "current", label: "Current", description: "Modern consoles & PC", icon: "gamecontroller.fill", match: { ["switch_1", "ps5", "xbox_series_xs", "pc", "macos"].contains($0.platformId) }),
        PlatformPreset(id: "nintendo", label: "Nintendo", description: "Switch & classics", icon: "gamecontroller.fill", match: { $0.family == "nintendo" }),
        PlatformPreset(id: "playstation", label: "PlayStation", description: "Sony platforms", icon: "gamecontroller.fill", match: { $0.family == "playstation" }),
        PlatformPreset(id: "xbox", label: "Xbox", description: "Microsoft platforms", icon: "gamecontroller.fill", match: { $0.family == "xbox" }),
        PlatformPreset(id: "pc", label: "PC", description: "Desktop platforms", icon: "laptopcomputer", match: { $0.family == "pc" || $0.kind == "computer" }),
        PlatformPreset(id: "retro", label: "Retro", description: "Classic systems", icon: "tv", match: { 
            ["snes", "n64", "wii", "ps2", "ps3", "xbox_360"].contains($0.platformId) ||
            ["sega", "atari", "snk", "neogeo"].contains($0.family)
        })
    ]

    var body: some View {
        ZStack {
            Color.playfitBackground.ignoresSafeArea()
            
            glowBackground
            
            ScrollView {
                VStack(alignment: .leading, spacing: PlayfitSpacing.md) {
                    Text("Recommendations are only shown for games available on your active platforms. Changes save automatically.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                    
                    // MARK: - Quick Groups (Presets)
                    Text("Quick Groups")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .padding(.horizontal, 4)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 180), spacing: PlayfitSpacing.sm)], spacing: PlayfitSpacing.sm) {
                        ForEach(platformPresets) { preset in
                            let totalPresetPlatforms = platformsToDisplay.filter(preset.match)
                            let selectedCount = totalPresetPlatforms.filter { viewModel.selectedPlatformIds.contains($0.platformId) }.count
                            let isFullySelected = !totalPresetPlatforms.isEmpty && selectedCount == totalPresetPlatforms.count
                            let isPartiallySelected = selectedCount > 0 && !isFullySelected
                            
                            Button {
                                withAnimation {
                                    togglePreset(preset, isFullySelected: isFullySelected)
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Image(systemName: preset.icon)
                                            .foregroundColor(isFullySelected || isPartiallySelected ? Color.playfitAccent : .secondary)
                                        Spacer()
                                        if isFullySelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Color.playfitAccent)
                                        } else if isPartiallySelected {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(Color.playfitAccent.opacity(0.6))
                                        }
                                    }
                                    
                                    Text(preset.label)
                                        .font(.subheadline.bold())
                                        .foregroundColor(.primary)
                                    
                                    Text(preset.description)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
                                .background(
                                    isFullySelected ? Color.playfitAccent.opacity(0.08) : Color.white.opacity(0.02),
                                    in: RoundedRectangle(cornerRadius: 14)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(isFullySelected ? Color.playfitAccent.opacity(0.3) : Color.primary.opacity(0.06), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // MARK: - Brand Tabs Selector
                    Text("Platforms by Brand")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .padding(.horizontal, 4)
                        .padding(.top, 8)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableFamilies, id: \.self) { family in
                                let familyPlatforms = platformsToDisplay.filter { platform in
                                    if family == "other" {
                                        return !["nintendo", "playstation", "xbox", "sega", "pc"].contains(platform.family)
                                    } else {
                                        return platform.family == family
                                    }
                                }
                                let selectedCount = familyPlatforms.filter { viewModel.selectedPlatformIds.contains($0.platformId) }.count
                                let totalCount = familyPlatforms.count
                                
                                Button {
                                    withAnimation {
                                        selectedFamily = family
                                    }
                                } label: {
                                    Text("\(familyDisplayName(family)) (\(selectedCount)/\(totalCount))")
                                        .font(.caption.bold())
                                        .foregroundColor(selectedFamily == family ? .white : .primary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedFamily == family ? Color.playfitAccent : Color.white.opacity(0.03),
                                            in: RoundedRectangle(cornerRadius: 12)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedFamily == family ? Color.playfitAccent : Color.primary.opacity(0.06), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    
                    // MARK: - Platforms Grid
                    PlayfitGlassCard {
                        let platformsInFamily = platformsToDisplay
                            .filter { platform in
                                if selectedFamily == "other" {
                                    return !["nintendo", "playstation", "xbox", "sega", "pc"].contains(platform.family)
                                } else {
                                    return platform.family == selectedFamily
                                }
                            }
                            .sorted(by: { $0.sortOrder < $1.sortOrder })
                        
                        if platformsInFamily.isEmpty {
                            Text("No platforms available in this category.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            let consoles = platformsInFamily.filter { $0.kind != "handheld" }
                            let handhelds = platformsInFamily.filter { $0.kind == "handheld" }
                            
                            VStack(alignment: .leading, spacing: PlayfitSpacing.md) {
                                if !consoles.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        if !handhelds.isEmpty {
                                            Text("Console / Hybrid")
                                                .font(.caption.bold())
                                                .foregroundColor(.secondary)
                                                .textCase(.uppercase)
                                                .padding(.horizontal, 6)
                                        }
                                        
                                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: PlayfitSpacing.sm) {
                                            ForEach(consoles) { platform in
                                                platformRow(platform)
                                            }
                                        }
                                    }
                                }
                                
                                if !handhelds.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Handheld")
                                            .font(.caption.bold())
                                            .foregroundColor(.secondary)
                                            .textCase(.uppercase)
                                            .padding(.horizontal, 6)
                                            .padding(.top, 4)
                                        
                                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: PlayfitSpacing.sm) {
                                            ForEach(handhelds) { platform in
                                                platformRow(platform)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(10)
                        }
                    }
                }
                .padding(PlayfitSpacing.md)
            }
        }
        .navigationTitle("Your Platforms")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    @ViewBuilder
    private func platformRow(_ platform: Platform) -> some View {
        let isSelected = viewModel.selectedPlatformIds.contains(platform.platformId)
        Button {
            withAnimation {
                if isSelected {
                    viewModel.selectedPlatformIds.remove(platform.platformId)
                } else {
                    viewModel.selectedPlatformIds.insert(platform.platformId)
                }
                LocalStorageService.shared.saveProfile(
                    viewModel.profile,
                    platformIds: viewModel.selectedPlatformIds,
                    onboardingCompleted: viewModel.onboardingCompleted
                )
            }
        } label: {
            HStack {
                Text(platform.displayName)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.playfitAccent)
                        .font(.title3)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary.opacity(0.5))
                        .font(.title3)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                isSelected ? Color.playfitAccent.opacity(0.06) : Color.clear,
                in: RoundedRectangle(cornerRadius: 10)
            )
        }
        .buttonStyle(.plain)
    }

    private var platformsToDisplay: [Platform] {
        if viewModel.platforms.isEmpty {
            return PlayViewModel.fallbackPlatforms
        } else {
            return viewModel.platforms
        }
    }

    private var availableFamilies: [String] {
        let standard = ["nintendo", "playstation", "xbox", "sega", "pc"]
        let hasOther = platformsToDisplay.contains { !standard.contains($0.family) }
        var list = ["nintendo", "playstation", "xbox", "sega", "pc"]
        if hasOther {
            list.append("other")
        }
        return list
    }

    private func togglePreset(_ preset: PlatformPreset, isFullySelected: Bool) {
        let presetPlatforms = platformsToDisplay.filter(preset.match)
        let presetIds = Set(presetPlatforms.map { $0.platformId })
        
        if isFullySelected {
            viewModel.selectedPlatformIds.subtract(presetIds)
        } else {
            viewModel.selectedPlatformIds.formUnion(presetIds)
        }
        
        LocalStorageService.shared.saveProfile(
            viewModel.profile,
            platformIds: viewModel.selectedPlatformIds,
            onboardingCompleted: viewModel.onboardingCompleted
        )
    }

    private func familyDisplayName(_ family: String) -> String {
        switch family {
        case "nintendo": "Nintendo"
        case "playstation": "PlayStation"
        case "xbox": "Xbox"
        case "sega": "SEGA"
        case "pc": "PC"
        case "other": "Other"
        default: family.capitalized
        }
    }

    private var glowBackground: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(Color.playfitAccent.opacity(0.12))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .position(x: geometry.size.width - 50, y: 100)
                
                Circle()
                    .fill(Color.playfitToneAccent.opacity(0.08))
                    .frame(width: 280, height: 280)
                    .blur(radius: 70)
                    .position(x: 50, y: geometry.size.height - 150)
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Developer Settings

#if DEBUG
private struct DeveloperSettingsView: View {
    @Environment(\.playViewModel) private var viewModel
    @State private var activeEnv = PlayfitAPI.activeEnvironment

    var body: some View {
        List {
            Section {
                Picker(selection: $activeEnv) {
                    ForEach(PlayfitAPI.Environment.allCases) { env in
                        Text(env.label).tag(env)
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.inline)
                .onChange(of: activeEnv) { _, newValue in
                    PlayfitAPI.activeEnvironment = newValue
                    viewModel.apiClient = HTTPPlayfitClient()
                    viewModel.showToast("API Switched to \(newValue.label)")
                    Task {
                        await viewModel.refresh()
                    }
                }
            } header: {
                Text("Backend Environment")
                    .textCase(.uppercase)
            } footer: {
                Text("Select whether the app queries your local dev server or the production API.")
            }

            Section("Active Configuration") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("API URL")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(activeEnv.url.absoluteString)
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
        .navigationTitle("Developer Settings")
    }
}
#endif

// MARK: - Privacy Settings View

private struct PrivacySettingsView: View {
    @Environment(\.playViewModel) private var viewModel
    @AppStorage("authEmail") private var authEmail: String = ""
    @State private var confirmReset = false
    @State private var confirmDelete = false
    @State private var actionPending = false
    
    var body: some View {
        ZStack {
            Color.playfitBackground.ignoresSafeArea()
            
            glowBackground
            
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reset Taste Profile")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.primary)
                        
                        Text("Deletes all taste preferences, ratings, library history, and platform selection. Your active account session stays, and you will restart calibration.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                        
                        HStack(spacing: 8) {
                            if confirmReset {
                                // Intentionally local-only: the backend's upsert_profile RPC rejects
                                // empty-overwrite payloads (profile/route.ts), so there is no safe way
                                // to push a "wipe taste" state to the server. The next full sync will
                                // re-upload local state once onboarding is redone.
                                Button(role: .destructive) {
                                    withAnimation {
                                        actionPending = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                            actionPending = false
                                            confirmReset = false
                                            viewModel.selectedPlatformIds.removeAll()
                                            viewModel.onboardingStarted = false
                                            viewModel.onboardingCompleted = false
                                            LocalStorageService.shared.saveProfile(viewModel.profile, platformIds: [], onboardingCompleted: false)
                                            viewModel.showToast("Profile reset completed", style: .success)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        if actionPending {
                                            ProgressView()
                                                .controlSize(.small)
                                                .tint(.white)
                                        } else {
                                            Text("Confirm Reset")
                                                .font(.caption.bold())
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .frame(minHeight: 44)
                                    .contentShape(Rectangle())
                                    .background(Color.red, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .disabled(actionPending)
                                
                                Button {
                                    withAnimation { confirmReset = false }
                                } label: {
                                    Text("Cancel")
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .frame(minHeight: 44)
                                        .contentShape(Rectangle())
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .disabled(actionPending)
                            } else {
                                Button {
                                    withAnimation { confirmReset = true }
                                } label: {
                                    Text("Reset Profile")
                                        .font(.caption.bold())
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .frame(minHeight: 44)
                                        .contentShape(Rectangle())
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 6)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Delete Cloud Profile")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.primary)
                        
                        Text("Permanently deletes your Playfit profile and synchronized taste data, clears local Playfit data, and signs you out. Your Supabase sign-in identity is not deleted.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                        
                        HStack(spacing: 8) {
                            if confirmDelete {
                                Button(role: .destructive) {
                                    actionPending = true
                                    Task {
                                        do {
                                            try await viewModel.deleteCloudProfile()
                                            await MainActor.run {
                                                authEmail = ""
                                                actionPending = false
                                                confirmDelete = false
                                                viewModel.showToast("Cloud profile deleted", style: .success)
                                            }
                                        } catch {
                                            await MainActor.run {
                                                actionPending = false
                                                viewModel.showToast("Delete failed: \(error.localizedDescription)", style: .error)
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        if actionPending {
                                            ProgressView()
                                                .controlSize(.small)
                                                .tint(.white)
                                        } else {
                                            Text("Confirm Delete")
                                                .font(.caption.bold())
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .frame(minHeight: 44)
                                    .contentShape(Rectangle())
                                    .background(Color.red, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .disabled(actionPending)
                                
                                Button {
                                    withAnimation { confirmDelete = false }
                                } label: {
                                    Text("Cancel")
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .frame(minHeight: 44)
                                        .contentShape(Rectangle())
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .disabled(actionPending)
                            } else {
                                Button {
                                    withAnimation { confirmDelete = true }
                                } label: {
                                    Text("Delete Cloud Profile")
                                        .font(.caption.bold())
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .frame(minHeight: 44)
                                        .contentShape(Rectangle())
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 6)
                } footer: {
                    Text("Manage your personal data, local taste storage, and account settings.")
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Data & Privacy")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private var glowBackground: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(Color.playfitAccent.opacity(0.12))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .position(x: geometry.size.width - 50, y: 100)
                
                Circle()
                    .fill(Color.playfitToneAccent.opacity(0.08))
                    .frame(width: 280, height: 280)
                    .blur(radius: 70)
                    .position(x: 50, y: geometry.size.height - 150)
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Sign In Sheet View

struct SignInSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.playViewModel) private var viewModel
    @Binding var authEmail: String
    
    @State private var authView: AuthView = .options
    @State private var emailInput = ""
    @State private var passwordInput = ""
    @State private var isLoading = false
    
    private enum AuthView {
        case options
        case signIn
        case signUp
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.playfitBackground.ignoresSafeArea()
                
                glowBackground
                
                ScrollView {
                    VStack(alignment: .center, spacing: PlayfitSpacing.md) {
                        
                        // Logo & Header
                        VStack(spacing: PlayfitSpacing.xs) {
                            Text("PLAYFIT DECISIONS")
                                .font(.caption2.monospaced().weight(.black))
                                .foregroundColor(.playfitAccent)
                                .tracking(2.5)
                                .padding(.top, 16)
                            
                            Text(titleForView)
                                .font(.system(.title, design: .rounded).weight(.black))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            Text(subtitleForView)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .lineSpacing(2)
                        }
                        .padding(.bottom, 8)
                        
                        switch authView {
                        case .options:
                            VStack(spacing: PlayfitSpacing.sm) {
                                // Google Button
                                Button {
                                    isLoading = true
                                    Task {
                                        do {
                                            try await viewModel.signInWithGoogle()
                                            authEmail = viewModel.authSession?.email ?? "Google account"
                                            isLoading = false
                                            dismiss()
                                        } catch AuthError.cancelled {
                                            isLoading = false
                                        } catch {
                                            isLoading = false
                                            viewModel.showToast("Google sign-in failed: \(error.localizedDescription)", style: .error)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: PlayfitSpacing.sm) {
                                        Spacer()
                                        if isLoading {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            googleLogo
                                            
                                            Text("Continue with Google")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.white)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(isLoading)
                                
                                // Email Button
                                Button {
                                    withAnimation {
                                        authView = .signIn
                                    }
                                } label: {
                                    HStack(spacing: PlayfitSpacing.sm) {
                                        Spacer()
                                        Image(systemName: "mail.fill")
                                            .foregroundColor(.playfitAccent)
                                        Text("Continue with Email")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(isLoading)
                                
                                // Guest Button
                                Button {
                                    dismiss()
                                } label: {
                                    HStack {
                                        Spacer()
                                        Text("Continue as Guest")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 14)
                                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .disabled(isLoading)
                                
                                // Toggle link to sign up
                                Button {
                                    withAnimation {
                                        authView = .signUp
                                    }
                                } label: {
                                    Text("New to Playfit? Create account")
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary)
                                        .underline()
                                        .padding(.top, 12)
                                }
                                .buttonStyle(.plain)
                            }
                            
                        case .signIn:
                            VStack(spacing: PlayfitSpacing.md) {
                                PlayfitGlassCard {
                                    VStack(alignment: .leading, spacing: PlayfitSpacing.sm) {
                                        Text("Email Address")
                                            .font(.caption.bold())
                                            .foregroundColor(.secondary)
                                        
                                        TextField("name@example.com", text: $emailInput)
                                            .textFieldStyle(.plain)
                                            .autocorrectionDisabled()
                                            #if os(iOS)
                                            .textInputAutocapitalization(.never)
                                            .keyboardType(.emailAddress)
                                            #endif
                                            .padding(12)
                                            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                            )
                                        
                                        Text("Password")
                                            .font(.caption.bold())
                                            .foregroundColor(.secondary)
                                            .padding(.top, 4)
                                        
                                        SecureField("••••••••", text: $passwordInput)
                                            .textFieldStyle(.plain)
                                            .padding(12)
                                            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                            )
                                    }
                                    .padding()
                                }
                                
                                Button {
                                    guard !emailInput.isEmpty && emailInput.contains("@") else {
                                        viewModel.showToast("Please enter a valid email address", style: .error)
                                        return
                                    }
                                    guard !passwordInput.isEmpty else {
                                        viewModel.showToast("Password cannot be empty", style: .error)
                                        return
                                    }
                                    isLoading = true
                                    Task {
                                        do {
                                            try await viewModel.signIn(email: emailInput, password: passwordInput)
                                            authEmail = emailInput
                                            isLoading = false
                                            dismiss()
                                        } catch {
                                            isLoading = false
                                            viewModel.showToast("Sign in failed: \(error.localizedDescription)", style: .error)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Spacer()
                                        if isLoading {
                                            ProgressView()
                                                .tint(.white)
                                                .padding(.trailing, 4)
                                        }
                                        Text(isLoading ? "Authenticating..." : "Sign In & Sync")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.vertical, 14)
                                    .background(Color.playfitAccent, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .disabled(isLoading)

                                Button {
                                    guard !emailInput.isEmpty else {
                                        viewModel.showToast("Enter your email address first.", style: .error)
                                        return
                                    }
                                    Task {
                                        do {
                                            try await viewModel.resetPassword(email: emailInput)
                                            viewModel.showToast("If that email is registered, you'll receive a reset link shortly.", style: .success)
                                        } catch {
                                            viewModel.showToast("Connection error. Please try again.", style: .error)
                                        }
                                    }
                                } label: {
                                    Text("Forgot password?")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .underline()
                                        .padding(.top, 2)
                                }
                                .buttonStyle(.plain)
                                .disabled(isLoading)

                                Button {
                                    withAnimation {
                                        authView = .signUp
                                    }
                                } label: {
                                    Text("Don't have an account? Create one")
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary)
                                        .underline()
                                        .padding(.top, 4)
                                }
                                .buttonStyle(.plain)
                            }

                        case .signUp:
                            VStack(spacing: PlayfitSpacing.md) {
                                PlayfitGlassCard {
                                    VStack(alignment: .leading, spacing: PlayfitSpacing.sm) {
                                        Text("Email Address")
                                            .font(.caption.bold())
                                            .foregroundColor(.secondary)
                                        
                                        TextField("name@example.com", text: $emailInput)
                                            .textFieldStyle(.plain)
                                            .autocorrectionDisabled()
                                            #if os(iOS)
                                            .textInputAutocapitalization(.never)
                                            .keyboardType(.emailAddress)
                                            #endif
                                            .padding(12)
                                            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                            )
                                        
                                        Text("Password")
                                            .font(.caption.bold())
                                            .foregroundColor(.secondary)
                                            .padding(.top, 4)
                                        
                                        SecureField("••••••••", text: $passwordInput)
                                            .textFieldStyle(.plain)
                                            .padding(12)
                                            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                            )
                                    }
                                    .padding()
                                }
                                
                                Button {
                                    guard !emailInput.isEmpty && emailInput.contains("@") else {
                                        viewModel.showToast("Please enter a valid email address", style: .error)
                                        return
                                    }
                                    guard passwordInput.count >= 6 else {
                                        viewModel.showToast("Password must be at least 6 characters", style: .error)
                                        return
                                    }
                                    isLoading = true
                                    Task {
                                        do {
                                            let hasSession = try await viewModel.signUp(email: emailInput, password: passwordInput)
                                            isLoading = false
                                            if hasSession {
                                                authEmail = emailInput
                                                dismiss()
                                            } else {
                                                viewModel.showToast("Check your email to confirm your account, then sign in.", style: .success)
                                                withAnimation { authView = .signIn }
                                            }
                                        } catch {
                                            isLoading = false
                                            viewModel.showToast("Sign up failed: \(error.localizedDescription)", style: .error)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Spacer()
                                        if isLoading {
                                            ProgressView()
                                                .tint(.white)
                                                .padding(.trailing, 4)
                                        }
                                        Text(isLoading ? "Registering..." : "Create Account")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.vertical, 14)
                                    .background(Color.playfitAccent, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .disabled(isLoading)
                                
                                Button {
                                    withAnimation {
                                        authView = .signIn
                                    }
                                } label: {
                                    Text("Already have an account? Sign In")
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary)
                                        .underline()
                                        .padding(.top, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(PlayfitSpacing.md)
                }
            }
            .navigationTitle(navTitleForView)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if authView != .options {
                        Button {
                            withAnimation {
                                authView = .options
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .disabled(isLoading)
                    } else {
                        Button("Cancel") {
                            dismiss()
                        }
                        .disabled(isLoading)
                    }
                }
            }
        }
    }
    
    private var googleLogo: some View {
        HStack(spacing: 0) {
            Text("G")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .yellow, .green, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: 22, height: 22)
        .background(.white, in: Circle())
    }
    
    private var titleForView: String {
        switch authView {
        case .options: "Welcome to Playfit"
        case .signIn: "Sign In"
        case .signUp: "Create Account"
        }
    }
    
    private var subtitleForView: String {
        switch authView {
        case .options: "Choose how you want to sync your library across devices."
        case .signIn: "Enter your email credentials to access your library."
        case .signUp: "Create an account to backup recommendations in the cloud."
        }
    }
    
    private var navTitleForView: String {
        switch authView {
        case .options: "Sign In / Sync"
        case .signIn: "Sign In"
        case .signUp: "Create Account"
        }
    }
    
    private var glowBackground: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(Color.playfitAccent.opacity(0.12))
                    .frame(width: 260, height: 260)
                    .blur(radius: 60)
                    .position(x: geometry.size.width - 50, y: 80)
            }
            .ignoresSafeArea()
        }
    }
}
