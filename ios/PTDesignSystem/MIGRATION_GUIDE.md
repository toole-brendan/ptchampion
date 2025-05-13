# Design System Migration Guide

## Overview

This guide explains the design token system migration from the legacy `AppTheme` namespace to standalone root-level token enums.

## Key Changes

1. **Removed Legacy Namespace**: The old `AppTheme` namespace has been completely removed
2. **Standalone Token Enums**: All design tokens now live in their own top-level enums
3. **Web Alignment**: Tokens match the web design tokens for cross-platform consistency

## New Structure

```swift
// Core namespaces - direct imports from DesignTokens
Color           // All color tokens (brand, semantic, status colors)
Typography      // All typography tokens (font sizes, styles)
CornerRadius    // All corner radius tokens
Shadow          // All shadow tokens (using DSShadow type)
Spacing         // All spacing tokens
```

## Migration Reference

### Old → New Token Reference

| Old Token                   | New Token                |
|-----------------------------|--------------------------|
| `AppTheme.Color.brand500`   | `Color.brand500`         |
| `AppTheme.Typography.h1`    | `Typography.h1`          |
| `AppTheme.Radius.lg`        | `CornerRadius.lg`        |
| `AppTheme.Shadow.md`        | `Shadow.md`              |
| `AppTheme.Spacing.space4`   | `Spacing.space4`         |
| `PTDesignSystem.*`          | Direct token enum access |

## Web Styling View Modifiers

We provide two convenience view modifiers for applying web-aligned styling:

```swift
// Apply card styling
myView.webCardStyle()

// Apply standard spacing
myView.webSpacing()

// With custom parameters
myView.webCardStyle(
    shadowStyle: Shadow.lg,
    cornerRadius: CornerRadius.md
)

myView.webSpacing(
    horizontal: Spacing.space8, 
    vertical: Spacing.space4
)
```

## Design System Toggle

For components that need to support both legacy and web styling:

```swift
// In component implementation:
let backgroundColor = ThemeManager.colorStyle(
    legacy: Color.cream,        // Legacy color
    web: Color.surface          // Web-aligned color
)

let cornerRadius = ThemeManager.radiusValue(
    legacy: CornerRadius.card,  // Legacy radius
    web: CornerRadius.lg        // Web-aligned radius
)

let shadow = ThemeManager.shadowStyle(
    legacy: Shadow.small,       // Legacy shadow
    web: Shadow.card            // Web-aligned shadow
)
```

## Shadow Usage

Shadows are implemented using the `DSShadow` type:

```swift
// Creating a custom shadow
let myShadow = DSShadow(
    color: Color.brand500.opacity(0.2),
    radius: 4,
    x: 0,
    y: 2
)

// Applying to a view
myView.withDSShadow(myShadow)

// Or using predefined shadows
myView.withDSShadow(Shadow.md)
```

## Future Improvements

To avoid namespace collisions with SwiftUI, in the future we may consider:

1. Prefixing tokens with "DS" (e.g., `DSColor`, `DSTypography`)
2. Using a single namespace (e.g., `DSToken.Color`, `DSToken.Typography`)

This would require a coordinated migration but would prevent shadowing SwiftUI types like `Color`. 