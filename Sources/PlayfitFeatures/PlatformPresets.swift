import PlayfitModels

struct PlatformPreset: Identifiable, Sendable {
    let id: String
    let label: String
    let description: String
    let icon: String
    let match: @Sendable (Platform) -> Bool
}

let platformPresets: [PlatformPreset] = [
    PlatformPreset(id: "current", label: "Current systems", description: "Modern consoles and computers.", icon: "gamecontroller.fill", match: { ["switch_1", "switch_2", "ps5", "xbox_series_xs", "pc", "macos", "linux", "cups"].contains($0.platformId) }),
    PlatformPreset(id: "nintendo", label: "Nintendo", description: "Switch, handhelds, and classic Nintendo.", icon: "n.circle.fill", match: { $0.family == "nintendo" }),
    PlatformPreset(id: "playstation", label: "PlayStation", description: "Sony home and handheld systems.", icon: "p.circle.fill", match: { $0.family == "playstation" }),
    PlatformPreset(id: "xbox", label: "Xbox", description: "Xbox generations and current consoles.", icon: "x.circle.fill", match: { $0.family == "xbox" }),
    PlatformPreset(id: "pc", label: "PC", description: "Desktop and computer platforms.", icon: "laptopcomputer", match: { $0.family == "pc" || $0.kind == "computer" }),
    PlatformPreset(id: "retro", label: "Retro", description: "Older consoles and handhelds.", icon: "arcade.stick.console.fill", match: {
        ["snes", "n64", "wii", "ps2", "ps3", "xbox_360", "xbox_original", "ps1",
         "game_boy_advance", "ds", "psp", "ps_vita", "gamecube", "gba", "gbc", "gb",
         "genesis", "sega_genesis", "wii_u", "dreamcast", "game_gear", "saturn",
         "sega_master_system", "nes", "atari_2600"].contains($0.platformId) ||
        ["sega", "atari", "snk"].contains($0.family)
    }),
]

let platformStandardFamilies = ["nintendo", "playstation", "xbox", "sega", "pc"]

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
