import PlayfitDesignSystem
import PlayfitModels
import SwiftUI

struct OnboardingPlatformsStep: View {
    @Environment(\.playViewModel) private var viewModel
    @Binding var selectedPlatformIds: Set<String>
    @Binding var showPlatformDetails: Bool
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PlayfitSpacing.lg) {
                Text("Where do you play?")
                    .font(.largeTitle.weight(.black))

                Text("We will only recommend games available on your active platforms.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Quick Groups")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                presetGrid

                Spacer(minLength: 24)

                VStack(spacing: 12) {
                    Button {
                        showPlatformDetails = true
                    } label: {
                        Text("Customize Platforms...")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.playfitAccent)
                    }
                    .buttonStyle(.plain)

                    Button {
                        onContinue()
                    } label: {
                        Text(selectedPlatformIds.isEmpty ? "Select at least one system" : "Continue")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedPlatformIds.isEmpty)
                }
            }
            .padding(PlayfitSpacing.md)
        }
    }

    private var presetGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(platformPresets, id: \.id) { preset in
                let selectedCount = presetSelectedCount(preset)
                let fullySelected = isPresetFullySelected(preset)
                let partiallySelected = selectedCount > 0 && !fullySelected

                Button {
                    withAnimation {
                        togglePreset(preset)
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        Color.clear.frame(height: 0)
                        HStack {
                            Image(systemName: preset.icon)
                                .font(.title3)
                                .foregroundStyle(fullySelected ? Color.playfitAccent : Color.secondary)
                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.label)
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                            Text(preset.description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        if fullySelected {
                            Text("Selected")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.playfitAccent)
                        } else if partiallySelected {
                            Text("\(selectedCount) Selected")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.secondary)
                        } else {
                            Text("Tap to Select")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        fullySelected ? Color.playfitAccent.opacity(0.12) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                fullySelected ? Color.playfitAccent.opacity(0.4) : Color.primary.opacity(0.06),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func togglePreset(_ preset: PlatformPreset) {
        let presetPlatforms = viewModel.platforms.filter(preset.match)
        let presetIds = Set(presetPlatforms.map(\.platformId))
        let allSelected = presetIds.allSatisfy { selectedPlatformIds.contains($0) }

        if allSelected {
            selectedPlatformIds.subtract(presetIds)
        } else {
            selectedPlatformIds.formUnion(presetIds)
        }
    }

    private func presetSelectedCount(_ preset: PlatformPreset) -> Int {
        let presetPlatforms = viewModel.platforms.filter(preset.match)
        let presetIds = Set(presetPlatforms.map(\.platformId))
        return presetIds.filter { selectedPlatformIds.contains($0) }.count
    }

    private func isPresetFullySelected(_ preset: PlatformPreset) -> Bool {
        let presetPlatforms = viewModel.platforms.filter(preset.match)
        let presetIds = Set(presetPlatforms.map(\.platformId))
        return !presetIds.isEmpty && presetIds.allSatisfy { selectedPlatformIds.contains($0) }
    }
}
