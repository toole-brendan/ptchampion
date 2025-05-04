# PTDesignSystem Usage Guide

## Overview

The PTDesignSystem is a Swift Package that provides a centralized design system derived from the project's `design-tokens.json` file at the root. This ensures a single source of truth for all styling across the application.

## Setup

The design system is already set up as a Swift Package at `ios/PTDesignSystem`. It contains:

- **DesignTokens**: Generated tokens from design-tokens.json (colors, typography, spacing, etc.)
- **Components**: Reusable UI components styled with the design tokens

## Using the Design System

### 1. Adding to Your Project

If the Swift Package is not already added to your Xcode project:

1. Open your Xcode project
2. Go to File > Add Packages...
3. Click "Add Local..."
4. Select the `ios/PTDesignSystem` directory
5. Click "Add Package"

### 2. Importing in Your Code

Import the entire package:

```swift
import PTDesignSystem
```

Or import specific modules for better granularity:

```swift
import DesignTokens  // For tokens only
import Components    // For UI components
```

### 3. Using Design Tokens

```swift
// Colors
Text("Hello, World!")
    .foregroundColor(AppTheme.GeneratedColors.primary)
    .background(AppTheme.GeneratedColors.background)

// Typography
Text("Heading")
    .font(AppTheme.GeneratedTypography.heading1())

// Spacing
VStack(spacing: AppTheme.GeneratedSpacing.medium) {
    // Content with standardized spacing
}

// Radius
RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.medium)

// Shadows
Rectangle()
    .withShadow(AppTheme.GeneratedShadows.medium)
```

### 4. Using Components

```swift
// Button component
PTButton("Sign In", style: .primary) {
    handleSignIn()
}

// Card component
PTCard {
    VStack {
        Text("Card Content")
    }
}

// Text field component
PTTextField("Email", text: $emailText)

// Label component
PTLabel("Username", style: .subtitle)
```

## Updating Design Tokens

When you make changes to the `design-tokens.json` file at the project root:

1. Run the token synchronization script:
   ```bash
   ./scripts/sync-design-tokens.sh
   ```

2. Rebuild your Xcode project to reflect the changes

## Adding New Components

To add a new component to the design system:

1. Create a new Swift file in `PTDesignSystem/Sources/Components/`
2. Use the design tokens from `DesignTokens` module for styling
3. Follow the same patterns as existing components
4. Add test cases in `PTDesignSystem/Tests/ComponentsTests/`

## Theming Support

The `ThemeManager` class handles theme switching (light/dark mode):

```swift
// Switch between light and dark mode
ThemeManager.shared.toggleDarkMode()

// Access current theme in views
@ObservedObject var themeManager = ThemeManager.shared
// ...
.preferredColorScheme(themeManager.currentColorScheme)
```

## Troubleshooting

### Missing Tokens

If you're not seeing recently added tokens:

1. Make sure the `sync-design-tokens.sh` script ran successfully
2. Check that the token is properly defined in design-tokens.json
3. Verify the generated Swift file includes the new token

### Import Errors

If you're seeing "No such module" errors:

1. Make sure the package is properly added to your Xcode project
2. Check that you're using the correct import statements
3. Clean your build folder (Shift+Cmd+K) and rebuild the project

## Migrating Existing Code

When migrating code from previous styling approaches:

1. Replace direct color/style references with design token references
2. Import the appropriate modules (DesignTokens or Components)
3. Use built-in components where possible instead of creating custom ones 