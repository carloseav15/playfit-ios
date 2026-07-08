import PlayfitModels

extension PlayViewModel {
    public static let fallbackPlatforms: [Platform] = [
        Platform(platformId: "switch_1", displayName: "Nintendo Switch", family: "nintendo", kind: "hybrid", sortOrder: 9),
        Platform(platformId: "switch_2", displayName: "Nintendo Switch 2", family: "nintendo", kind: "hybrid", sortOrder: 10),
        Platform(platformId: "ps5", displayName: "PlayStation 5", family: "playstation", kind: "console", sortOrder: 9),
        Platform(platformId: "ps4", displayName: "PlayStation 4", family: "playstation", kind: "console", sortOrder: 8),
        Platform(platformId: "xbox_series_xs", displayName: "Xbox Series X|S", family: "xbox", kind: "console", sortOrder: 9),
        Platform(platformId: "xbox_one", displayName: "Xbox One", family: "xbox", kind: "console", sortOrder: 8),
        Platform(platformId: "pc", displayName: "PC", family: "pc", kind: "computer", sortOrder: 10),
        Platform(platformId: "macos", displayName: "Mac", family: "pc", kind: "computer", sortOrder: 9),
        Platform(platformId: "snes", displayName: "Super Nintendo", family: "nintendo", kind: "console", sortOrder: 4),
        Platform(platformId: "n64", displayName: "Nintendo 64", family: "nintendo", kind: "console", sortOrder: 5),
        Platform(platformId: "wii", displayName: "Nintendo Wii", family: "nintendo", kind: "console", sortOrder: 7),
        Platform(platformId: "ps2", displayName: "PlayStation 2", family: "playstation", kind: "console", sortOrder: 6),
        Platform(platformId: "ps3", displayName: "PlayStation 3", family: "playstation", kind: "console", sortOrder: 7),
        Platform(platformId: "xbox_360", displayName: "Xbox 360", family: "xbox", kind: "console", sortOrder: 7)
    ]
}
