# PT Champion Design System

This package provides a comprehensive design token system for the PT Champion app, ensuring consistency across the codebase and making it easier to maintain a cohesive visual language.

## Design Token Usage Guidelines

When working with the PT Champion codebase, always use the design tokens provided by the `PTDesignSystem` package. This ensures visual consistency and makes future design updates easier to implement.

### Colors

- Use `AppTheme.GeneratedColors` for all color references
- Never use direct SwiftUI Color creation with RGB values or hex codes
- Available semantic colors include:
  - Primary colors: `primary`, `secondary`, `accent`
  - Brand colors: `deepOps`, `brassGold`, `armyTan`, `oliveMist`, etc.
  - Text colors: `textPrimary`, `textSecondary`, `textTertiary`, `textOnPrimary`
  - Status colors: `success`, `error`, `warning`, `info`
  - Background colors: `background`, `cardBackground`

### Typography

- Use `AppTheme.GeneratedTypography` for all font styling
- Never use `Font.custom(...)` directly
- Available typography functions:
  - `heading()`, `heading2()`, `heading3()`, etc.
  - `subheading()`
  - `body()`, `bodyBold()`, `bodySemibold()`
  - `caption()`, `captionBold()`
  - Size-specific variants (with custom sizing)

### Spacing

- Use `AppTheme.GeneratedSpacing` for all spacing values
- Never use hardcoded numeric values for padding, spacing or offsets
- Available spacing tokens:
  - `extraSmall` (4pt)
  - `small` (8pt)
  - `medium` (16pt) 
  - `large` (24pt)
  - `section` (32pt)
  - Specialized spacing: `itemSpacing`, `contentPadding`

### Border Radius

- Use `AppTheme.GeneratedRadius` for all corner radius values
- Never use hardcoded numeric values for cornerRadius
- Available radius tokens:
  - `small` (4pt)
  - `medium` (8pt)
  - `large` (12pt)
  - `card` for standard card elements
  - `full` for pill shapes (9999pt)

### Components

Whenever possible, use the pre-built components from PTDesignSystem rather than creating custom implementations:

- `PTButton` instead of SwiftUI Button
- `PTLabel` instead of SwiftUI Text
- `PTTextField` instead of SwiftUI TextField
- `PTSeparator` instead of custom Separator or Divider
- `PTCard` for card-based layouts

### Adding New Design Tokens

If you need a new design token:

1. Add it as an extension to the appropriate AppTheme.Generated* enum
2. Document it properly with comments
3. Consider if it should be added to the core design system for reuse

## Linting

The codebase includes SwiftLint rules to enforce the use of design tokens. These rules will catch:

- Direct color creation with RGB values
- Magic numbers in spacing
- Magic numbers in corner radius
- Legacy AppTheme.Colors usage
- Direct Font.custom usage

Follow these guidelines to ensure a consistent, maintainable codebase. 