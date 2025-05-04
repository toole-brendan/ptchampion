// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "PTDesignSystem",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "PTDesignSystem",
            targets: ["DesignTokens", "Components"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "DesignTokens",
            dependencies: [],
            resources: [.process("Resources/Colors.xcassets")]),
        .target(
            name: "Components",
            dependencies: ["DesignTokens"],
            resources: []),
        .testTarget(
            name: "DesignTokensTests",
            dependencies: ["DesignTokens"]),
        .testTarget(
            name: "ComponentsTests",
            dependencies: ["Components"]),
    ]
) 