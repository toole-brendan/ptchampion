# Design Tokens

Design tokens are the single source of truth for your design system.

## Overview

Design tokens are a technology-agnostic way to store variables such as colors, typography, and spacing. They're platform-independent so they can be transformed into any format needed for web, iOS, Android, or any other platform.

PT Champion uses a design token pipeline built on [Style Dictionary](https://amzn.github.io/style-dictionary/) that automatically generates:

- CSS variables for web
- Swift code for iOS
- Color assets for iOS

## Accessing Tokens

### In iOS

Design tokens are accessible via generated code:

```swift
// Colors
let primary = AppTheme.GeneratedColors.deepOps

// Typography
let heading = AppTheme.GeneratedTypography.heading(size: 24)

// Spacing
let padding = AppTheme.GeneratedSpacing.contentPadding
```

### In Web

Design tokens are available as CSS custom properties:

```css
.my-element {
  color: var(--primary);
  padding: var(--spacing-md);
  font-family: var(--font-heading);
}
```

## Token Categories

### Colors

Military-inspired color palette with semantic naming:

- Deep Ops (primary dark blue)
- Brass Gold (accent)
- Tactical Gray (neutral)
- Army Tan (earth tones)
- Command Black (deep black)
- Cream (background)

### Typography

Typography tokens define both the font families and size scales:

- Heading (Bebas Neue Bold)
- Body (Montserrat)
- Mono (Roboto Mono)

### Spacing

Consistent spacing helps maintain visual harmony:

- XS: 4pt
- SM: 8pt 
- MD: 16pt
- LG: 24pt
- XL: 32pt

### Borders & Radii

Border radius tokens create consistent corner treatments:

- Button: 8pt
- Card: 12pt
- Panel: 16pt

## Token Pipeline

The token pipeline works as follows:

1. Edit `design-tokens.json` in the design-tokens directory
2. Run the build script
3. Auto-generated code is created for all platforms
4. Import the generated code into your app

The CI system automatically validates token changes to prevent drift between platforms. 