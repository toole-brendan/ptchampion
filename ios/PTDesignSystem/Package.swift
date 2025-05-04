// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PTDesignSystem",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "PTDesignSystem",
            targets: ["PTDesignSystem"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "DesignTokens",
            dependencies: [],
            resources: [.process("Resources/Colors.xcassets")]
        ),
        .target(
            name: "Components",
            dependencies: ["DesignTokens"]
        ),
        .target(
            name: "PTDesignSystem",
            dependencies: ["Components", "DesignTokens"]
        ),
        .testTarget(
            name: "DesignTokensTests",
            dependencies: ["DesignTokens"]
        ),
        .testTarget(
            name: "ComponentsTests",
            dependencies: ["Components"]
        ),
    ]
) 