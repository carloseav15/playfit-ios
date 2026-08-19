// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PlayfitIOS",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "PlayfitModels", targets: ["PlayfitModels"]),
        .library(name: "PlayfitMocks", targets: ["PlayfitMocks"]),
        .library(name: "PlayfitDesignSystem", targets: ["PlayfitDesignSystem"]),
        .library(name: "PlayfitLogic", targets: ["PlayfitLogic"]),
        .library(name: "PlayfitAPI", targets: ["PlayfitAPI"]),
        .library(name: "PlayfitFeatures", targets: ["PlayfitFeatures"]),
        .executable(name: "PlayfitSmokeCheck", targets: ["PlayfitSmokeCheck"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "PlayfitModels"),
        .target(
            name: "PlayfitMocks",
            dependencies: ["PlayfitModels"]
        ),
        .target(
            name: "PlayfitDesignSystem",
            dependencies: ["PlayfitModels"]
        ),
        .target(
            name: "PlayfitLogic",
            dependencies: ["PlayfitModels"]
        ),
        .target(
            name: "PlayfitAPI",
            dependencies: [
                "PlayfitModels",
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .target(
            name: "PlayfitStorage",
            dependencies: [
                "PlayfitModels",
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .target(
            name: "PlayfitFeatures",
            dependencies: [
                "PlayfitAPI",
                "PlayfitModels",
                "PlayfitDesignSystem",
                "PlayfitLogic",
                "PlayfitStorage",
            ]
        ),
        .executableTarget(
            name: "PlayfitSmokeCheck",
            dependencies: [
                "PlayfitAPI",
                "PlayfitModels",
                "PlayfitLogic",
                "PlayfitFeatures",
                "PlayfitMocks",
            ]
        ),
        .testTarget(
            name: "PlayfitModelsTests",
            dependencies: ["PlayfitModels"]
        ),
        .testTarget(
            name: "PlayfitAPITests",
            dependencies: ["PlayfitAPI", "PlayfitModels"],
            resources: [.process("Fixtures")]
        ),
        .testTarget(
            name: "PlayfitLogicTests",
            dependencies: ["PlayfitLogic", "PlayfitModels"]
        ),
        .testTarget(
            name: "PlayfitFeaturesTests",
            dependencies: ["PlayfitFeatures", "PlayfitModels"]
        ),
    ]
)
