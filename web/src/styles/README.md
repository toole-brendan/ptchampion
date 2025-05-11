
# PT Champion Design System

This directory contains the core design system files for PT Champion's web application, derived from the iOS design tokens in `ios/PTDesignSystem/`.

## Files

- `ios-tokens.css` - CSS variables extracted from iOS AppTheme+Generated.swift
- `fonts.css` - Font declarations matching the iOS font system

## Usage

These design tokens are automatically imported in `index.css` and mapped to Tailwind CSS classes through the `tailwind.config.js` file.

### Available Tokens

- **Colors**: Base colors (cream, brass-gold, etc.) and semantic colors (primary, secondary, etc.)
- **Typography**: Font sizes and font families
- **Spacing**: Size scales for padding, margin, gaps
- **Shadows**: Small, medium, and large elevation
- **Border Radius**: Various border radius values

### Utility Classes

Beyond Tailwind's utilities, we've created custom component classes:

- `.card` - Standard card component
- `.card-interactive` - Interactive card with hover effects
- `.panel` - Panel with larger radius and padding 
- `.btn-primary`, `.btn-secondary`, `.btn-outline` - Button variants
- `.shimmer` - Loading animation for placeholders
- `.bottom-nav` and `.bottom-nav-item` - Mobile navigation bar styling

## Dark Mode

Dark mode tokens are defined under the `.dark` selector in `ios-tokens.css`. Activate dark mode by adding the `dark` class to the `<html>` element.

## Customization

To update these design tokens, modify the source files in the iOS module and regenerate rather than editing these files directly. 