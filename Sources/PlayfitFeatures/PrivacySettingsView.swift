import PlayfitDesignSystem
import PlayfitModels
import SwiftUI

// MARK: - Privacy Settings View

struct PrivacySettingsView: View {
    @Environment(\.playViewModel) private var viewModel
    @AppStorage(StorageKeys.authEmail) private var authEmail: String = ""
    @State private var confirmReset = false
    @State private var confirmDelete = false
    @State private var actionPending = false
    
    var body: some View {
        ZStack {
            Color.playfitBackground.ignoresSafeArea()
            
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
                                // Deletes the remote profile via the same DELETE /api/profile
                                // used by "Delete Cloud Profile", but keeps the session active
                                // (no sign-out) — matches web/Android's reset semantics.
                                Button(role: .destructive) {
                                    withAnimation {
                                        actionPending = true
                                    }
                                    Task {
                                        do {
                                            try await viewModel.resetTasteCloudProfile()
                                            await MainActor.run {
                                                withAnimation {
                                                    actionPending = false
                                                    confirmReset = false
                                                    viewModel.showToast("Profile reset completed", style: .success)
                                                }
                                            }
                                        } catch {
                                            await MainActor.run {
                                                withAnimation {
                                                    actionPending = false
                                                }
                                                viewModel.showToast("Operation failed. Please try again later.", style: .error)
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        if actionPending {
                                            ProgressView()
                                                .controlSize(.small)
                                                .tint(Color.playfitNegativeForeground)
                                        } else {
                                            Text("Confirm Reset")
                                                .font(.caption.bold())
                                                .foregroundColor(Color.playfitNegativeForeground)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .frame(minHeight: 44)
                                    .contentShape(Rectangle())
                                    .background(Color.playfitNegative, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Confirm Reset")
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
                                .accessibilityLabel("Reset Profile")
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
                                                viewModel.showToast("Operation failed. Please try again later.", style: .error)
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        if actionPending {
                                            ProgressView()
                                                .controlSize(.small)
                                                .tint(Color.playfitNegativeForeground)
                                        } else {
                                            Text("Confirm Delete")
                                                .font(.caption.bold())
                                                .foregroundColor(Color.playfitNegativeForeground)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .frame(minHeight: 44)
                                    .contentShape(Rectangle())
                                    .background(Color.playfitNegative, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Confirm Delete")
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
                                .accessibilityLabel("Delete Cloud Profile")
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
    
}
