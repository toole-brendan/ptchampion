// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "PTDesignSystem",
    platforms: [
        .iOS(.v14),        // already there
        .macOS(.v11),      // ← add this line
        .tvOS(.v14),       // (optional) if you ever use tvOS
        .watchOS(.v7)      // (optional) for watchOS
    ],
    products: [
        // — 1 — Pure token model & utilities (no SwiftUI)
        .library(
            name: "DesignTokens",
            type: .static,                  // static is fine; dynamic also works
            targets: ["DesignTokens"]
        ),

        // — 2 — SwiftUI components (depends on tokens)
        .library(
            name: "Components",
            type: .static,
            targets: ["Components"]
        ),

        // — 3 — Umbrella / façade (tiny target, re-exports the others)
        .library(
            name: "PTDesignSystem",
            type: .static,                  // can be dynamic if you prefer
            targets: ["PTDesignSystem"]
        )
    ],
    dependencies: [
        // Updated to use the exact version 1.3.0 that we confirmed is available
        .package(url: "https://github.com/siteline/SwiftUI-Introspect.git", 
                exact: "1.3.0")
    ],
    targets: [
        .target(
            name: "DesignTokens",
            path: "Sources/DesignTokens",
            resources: [
                .process("Resources/Colors.xcassets")
            ]
        ),
        .target(
            name: "Components",
            dependencies: [
                "DesignTokens",
                .product(name: "SwiftUIIntrospect", package: "SwiftUI-Introspect")
            ],
            path: "Sources/Components"
        ),
        .target(
            name: "PTDesignSystem",
            dependencies: [
                "Components",
                "DesignTokens"
            ],
            path: "Sources/PTDesignSystem"   // contains Umbrella.swift
        )
    ]
)
