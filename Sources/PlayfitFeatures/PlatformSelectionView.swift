import PlayfitDesignSystem
import PlayfitModels
import PlayfitStorage
import SwiftUI

// MARK: - Platform Selection

struct PlatformSelectionView: View {
    @Environment(\.playViewModel) private var viewModel
    @State private var selectedFamily: String = "nintendo"

    var body: some View {
        ZStack {
            Color.playfitBackground.ignoresSafeArea()
            
            PlayfitGlowBackground()
            
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
                            .accessibilityLabel("\(preset.label): \(preset.description)")
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
        .accessibilityLabel("\(platform.displayName): \(isSelected ? "selected" : "not selected")")
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

}
