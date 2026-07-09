import PlayfitAPI
import SwiftUI

// MARK: - Developer Settings

#if DEBUG
struct DeveloperSettingsView: View {
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
                    Text("Backend Environment")
                }
                .pickerStyle(.inline)
                .accessibilityLabel("Backend Environment Selection")
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
