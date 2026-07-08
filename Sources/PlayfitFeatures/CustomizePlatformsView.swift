import PlayfitDesignSystem
import SwiftUI

struct CustomizePlatformsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.playViewModel) private var viewModel
    @Binding var selectedPlatformIds: Set<String>

    var body: some View {
        NavigationStack {
            List {
                let families = Dictionary(grouping: viewModel.platforms, by: { $0.family })
                ForEach(Array(families.keys).sorted(), id: \.self) { family in
                    Section(familyDisplayName(family)) {
                        ForEach(families[family, default: []], id: \.platformId) { platform in
                            Button {
                                if selectedPlatformIds.contains(platform.platformId) {
                                    selectedPlatformIds.remove(platform.platformId)
                                } else {
                                    selectedPlatformIds.insert(platform.platformId)
                                }
                            } label: {
                                HStack {
                                    Text(platform.displayName)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedPlatformIds.contains(platform.platformId) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.title3)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.tertiary)
                                            .font(.title3)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
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
}
