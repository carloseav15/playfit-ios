import PlayfitDesignSystem
import SwiftUI

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

struct AppearanceView: View {
    @Binding var appearanceMode: AppearanceMode

    var body: some View {
        ZStack {
            Color.playfitBackground.ignoresSafeArea()
            
            PlayfitGlowBackground()
            
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
                                .accessibilityLabel("\(mode.label) theme")
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

}
