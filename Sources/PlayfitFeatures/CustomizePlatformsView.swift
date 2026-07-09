import PlayfitDesignSystem
import PlayfitModels
import SwiftUI

struct CustomizePlatformsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.playViewModel) private var viewModel
    @Binding var selectedPlatformIds: Set<String>

    private var allSelected: Bool {
        !viewModel.platforms.isEmpty && selectedPlatformIds.count == viewModel.platforms.count
    }

    private func platforms(for family: String) -> [Platform] {
        if family == "other" {
            return viewModel.platforms
                .filter { !platformStandardFamilies.contains($0.family) }
                .sorted { $0.sortOrder < $1.sortOrder }
        }
        return viewModel.platforms
            .filter { $0.family == family }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        if allSelected {
                            selectedPlatformIds.removeAll()
                        } else {
                            selectedPlatformIds = Set(viewModel.platforms.map { $0.platformId })
                        }
                    } label: {
                        HStack {
                            Image(systemName: allSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(allSelected ? Color.playfitAccent : Color.gray.opacity(0.5))
                                .font(.title3)
                            Text(allSelected ? "Deselect all platforms" : "Select all platforms")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.plain)
                }

                let families: [String] = {
                    let platformFamilies = Set(viewModel.platforms.map { $0.family })
                    var ordered = platformStandardFamilies.filter { platformFamilies.contains($0) }
                    let hasOther = platformFamilies.contains { !platformStandardFamilies.contains($0) }
                    if hasOther { ordered.append("other") }
                    return ordered
                }()

                ForEach(families, id: \.self) { family in
                    let familyPlatforms = platforms(for: family)
                    if !familyPlatforms.isEmpty {
                        Section(familyDisplayName(family)) {
                            let consoles = familyPlatforms.filter { $0.kind != "handheld" }
                            let handhelds = familyPlatforms.filter { $0.kind == "handheld" }

                            if !consoles.isEmpty {
                                if !handhelds.isEmpty {
                                    Text("Console / Hybrid")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.secondary)
                                        .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 0))
                                }
                                ForEach(consoles, id: \.platformId) { platform in
                                    PlatformToggleRow(
                                        platform: platform,
                                        isSelected: selectedPlatformIds.contains(platform.platformId),
                                        onToggle: { toggle(platform.platformId) }
                                    )
                                }
                            }

                            if !handhelds.isEmpty {
                                Text("Handheld")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 0))
                                ForEach(handhelds, id: \.platformId) { platform in
                                    PlatformToggleRow(
                                        platform: platform,
                                        isSelected: selectedPlatformIds.contains(platform.platformId),
                                        onToggle: { toggle(platform.platformId) }
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Customize Platforms")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func toggle(_ platformId: String) {
        if selectedPlatformIds.contains(platformId) {
            selectedPlatformIds.remove(platformId)
        } else {
            selectedPlatformIds.insert(platformId)
        }
    }
}

private struct PlatformToggleRow: View {
    let platform: Platform
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.playfitAccent : Color.gray.opacity(0.5))
                    .font(.title3)
                Text(platform.displayName)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(platform.displayName), \(isSelected ? "selected" : "not selected")")
    }
}
