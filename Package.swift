// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "PTChampion",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "PTChampionUI",
            targets: ["PTChampionUI"]),
        .plugin(
            name: "DesignTokenGenPlugin", 
            targets: ["DesignTokenGenPlugin"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PTChampionUI",
            dependencies: [],
            plugins: [
                .plugin(name: "DesignTokenGenPlugin")
            ]
        ),
        .executableTarget(
            name: "DesignTokenGenTool",
            path: "Tools/DesignTokenGenTool"),
        .plugin(
            name: "DesignTokenGenPlugin",
            capability: .buildTool(),
            dependencies: [
                .target(name: "DesignTokenGenTool")
            ]),
    ]
) 