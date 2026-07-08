import PlayfitModels

struct PlatformPreset: Identifiable, Sendable {
    let id: String
    let label: String
    let description: String
    let icon: String
    let match: @Sendable (Platform) -> Bool
}

let platformPresets: [PlatformPreset] = [
    PlatformPreset(id: "current", label: "Current systems", description: "Modern consoles and computers.", icon: "gamecontroller.fill", match: { ["switch_1", "ps5", "xbox_series_xs", "pc", "macos"].contains($0.platformId) }),
    PlatformPreset(id: "nintendo", label: "Nintendo", description: "Switch, handhelds, and classic Nintendo.", icon: "gamecontroller.fill", match: { $0.family == "nintendo" }),
    PlatformPreset(id: "playstation", label: "PlayStation", description: "Sony home and handheld systems.", icon: "gamecontroller.fill", match: { $0.family == "playstation" }),
    PlatformPreset(id: "xbox", label: "Xbox", description: "Xbox generations and current consoles.", icon: "gamecontroller.fill", match: { $0.family == "xbox" }),
    PlatformPreset(id: "pc", label: "PC", description: "Desktop and computer platforms.", icon: "laptopcomputer", match: { $0.family == "pc" || $0.kind == "computer" }),
    PlatformPreset(id: "retro", label: "Retro", description: "Older consoles and handhelds.", icon: "tv", match: {
        ["snes", "n64", "wii", "ps2", "ps3", "xbox_360"].contains($0.platformId) ||
        ["sega", "atari", "snk", "neogeo"].contains($0.family)
    }),
]

func familyDisplayName(_ family: String) -> String {
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
