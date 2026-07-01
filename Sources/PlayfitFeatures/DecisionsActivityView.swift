import PlayfitDesignSystem
import PlayfitModels
import PlayfitLogic
import SwiftUI

public struct DecisionsActivityView: View {
    @Environment(\.playViewModel) private var viewModel
    @State private var activeTab: ActivityTab = .all
    @State private var signalToManage: TasteHistoryEntry?
    @State private var signalToChange: TasteHistoryEntry?
    
    public init() {}
    
    private enum ActivityTab {
        case all, active, taste
    }
    
    public var body: some View {
        let history = buildTasteHistoryEntries(
            gameStates: viewModel.gameStates,
            onboardingLikedIds: [],
            onboardingDislikedIds: [],
            gamesCache: viewModel.gamesCache
        )
        
        let filtered = history.filter { entry in
            switch activeTab {
            case .all: true
            case .active: entry.decision == "picks"
            case .taste: entry.decision != "picks"
            }
        }
        
        ZStack {
            Color.playfitBackground.ignoresSafeArea()
            
            VStack(spacing: PlayfitSpacing.sm) {
                // Tab Picker Selection
                Picker("Activity Filters", selection: $activeTab) {
                    Text("All (\(history.count))").tag(ActivityTab.all)
                    Text("Picks (\(history.filter { $0.decision == "picks" }.count))").tag(ActivityTab.active)
                    Text("Taste (\(history.filter { $0.decision != "picks" }.count))").tag(ActivityTab.taste)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // List of logs
                if filtered.isEmpty {
                    VStack {
                        Spacer()
                        Text("No ratings or activity matched this filter.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: PlayfitSpacing.sm) {
                            ForEach(filtered, id: \.gameId) { entry in
                                ActivityRow(
                                    entry: entry,
                                    game: viewModel.gamesCache[entry.gameId],
                                    onManage: {
                                        signalToManage = entry
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .confirmationDialog(
            "Manage Signal",
            isPresented: Binding(
                get: { signalToManage != nil },
                set: { if !$0 { signalToManage = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let entry = signalToManage {
                if entry.decision == "picks" {
                    Button("Remove from Picks", role: .destructive) {
                        viewModel.removePick(entry.gameId)
                        signalToManage = nil
                    }
                } else {
                    Button("Change Signal") {
                        signalToChange = entry
                        signalToManage = nil
                    }
                    Button("Delete Signal", role: .destructive) {
                        viewModel.deleteSignal(entry.gameId)
                        signalToManage = nil
                    }
                }
                
                Button("Cancel", role: .cancel) {
                    signalToManage = nil
                }
            }
        } message: {
            if let entry = signalToManage {
                Text("Choose an action for \(entry.title)")
            }
        }
        .sheet(item: $signalToChange) { entry in
            ChangeSignalSheet(title: entry.title) { feedback in
                viewModel.updateSignal(gameId: entry.gameId, feedback: feedback)
            }
        }
    }
    
    private func badgeLabel(_ entry: TasteHistoryEntry) -> String {
        switch entry.decision {
        case "picks": "Saved Pick"
        case "setup_favorite": "Setup: Loved"
        case "setup_miss": "Setup: Missed"
        case "loved": "Loved"
        case "liked": "Liked"
        case "mixed": "Mixed"
        case "dropped": "Dropped"
        case "not_for_me": "Not For Me"
        default: "Rated"
        }
    }
    
    private func badgeColor(_ entry: TasteHistoryEntry) -> Color {
        switch entry.tone {
        case "positive": Color.playfitPositive
        case "negative": Color.playfitNegative
        default: Color.secondary
        }
    }
    
    private func formatDateString(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: isoString) else { return "Recent" }
        
        let output = DateFormatter()
        output.dateStyle = .medium
        output.timeStyle = .none
        return output.string(from: date)
    }
}

struct ActivityRow: View {
    let entry: TasteHistoryEntry
    let game: Game?
    let onManage: () -> Void
    
    var body: some View {
        HStack(spacing: PlayfitSpacing.md) {
            // Cover
            if let game = game {
                PlayfitCoverPlaceholder(title: game.title)
                    .frame(width: 44, height: 60)
                    .cornerRadius(8)
            } else {
                Color.primary.opacity(0.04)
                    .frame(width: 44, height: 60)
                    .cornerRadius(8)
            }
            
            // Text info
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(badgeLabel(entry))
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(badgeColor(entry))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(badgeColor(entry).opacity(0.10), in: Capsule())
                    
                    if let rating = entry.rating, rating > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 7))
                            Text(String(format: "%.0f", rating))
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Text(entry.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(entry.updatedAt != nil ? formatDateString(entry.updatedAt!) : "Baseline")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Menu / Options
            Button(action: onManage) {
                Image(systemName: "ellipsis")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
    
    private func badgeLabel(_ entry: TasteHistoryEntry) -> String {
        switch entry.decision {
        case "picks": "Saved Pick"
        case "setup_favorite": "Setup: Loved"
        case "setup_miss": "Setup: Missed"
        case "loved": "Loved"
        case "liked": "Liked"
        case "mixed": "Mixed"
        case "dropped": "Dropped"
        case "not_for_me": "Not For Me"
        default: "Rated"
        }
    }
    
    private func badgeColor(_ entry: TasteHistoryEntry) -> Color {
        switch entry.tone {
        case "positive": Color.playfitPositive
        case "negative": Color.playfitNegative
        default: Color.secondary
        }
    }
    
    private func formatDateString(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: isoString) else { return "Recent" }
        
        let output = DateFormatter()
        output.dateStyle = .medium
        output.timeStyle = .none
        return output.string(from: date)
    }
}

extension TasteHistoryEntry: Identifiable {
    public var id: String { gameId }
}

struct ChangeSignalSheet: View {
    let title: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.playfitBackground.ignoresSafeArea()
            
            VStack(spacing: PlayfitSpacing.md) {
                // Header
                HStack {
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.playfitAccent)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("How did it land?")
                        .font(.title3.weight(.black))
                    Text("Update your taste footprint for \(title)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Options list
                VStack(spacing: PlayfitSpacing.sm) {
                    optionRow(label: "Loved", sub: "Excellent gameplay and loop", icon: "heart.fill", color: .playfitPositive, val: "played_loved")
                    optionRow(label: "Liked", sub: "Solid experience worth playing", icon: "hand.thumbsup.fill", color: .playfitPositive, val: "played_liked")
                    optionRow(label: "Mixed", sub: "Good elements but had issues", icon: "waveform", color: .yellow, val: "played_mixed")
                    optionRow(label: "Dropped", sub: "Lost interest or didn't finish", icon: "hand.thumbsdown.fill", color: .playfitNegative, val: "played_dropped")
                    optionRow(label: "Not For Me", sub: "Avoid recommending similar games", icon: "xmark.octagon.fill", color: .playfitNegative, val: "not_for_me")
                }
                .padding()
                
                Spacer()
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func optionRow(label: String, sub: String, icon: String, color: Color, val: String) -> some View {
        Button {
            onSelect(val)
            dismiss()
        } label: {
            HStack(spacing: PlayfitSpacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Text(sub)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.4))
            }
            .padding(10)
            .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
