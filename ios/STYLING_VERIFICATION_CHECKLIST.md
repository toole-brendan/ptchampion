# iOS Styling Integration Verification Checklist

Use this checklist to verify that all aspects of the styling integration have been completed properly.

## Color Usage

- [ ] All direct color references (`Color.brassGold`, `.deepOps`, etc.) replaced with `AppTheme.GeneratedColors.X`
- [ ] No more usage of `AppTheme.Colors` (deprecated)
- [ ] All color values come from the generated files

## Typography

- [ ] All static font sizes (`.font(.title)`) replaced with `AppTheme.GeneratedTypography`
- [ ] All custom font usage (`Font.custom("BebasNeue-Bold", size: 24)`) replaced with semantic typography tokens
- [ ] Dynamic type supported on all text elements
- [ ] No more usage of AppTheme.Typography (deprecated)

## Spacing and Layout

- [ ] Magic numbers in padding and spacing replaced with `AppTheme.GeneratedSpacing`
- [ ] Consistent spacing system used throughout the app
- [ ] No hardcoded values for UI element sizing

## Borders and Radius

- [ ] All `cornerRadius(8)` replaced with `AppTheme.GeneratedRadius.X`
- [ ] Border styles consistent with design system tokens

## Accessibility

- [ ] Dark mode works correctly on all screens
- [ ] All colors meet WCAG AA contrast requirements (use UIColorContrastChecker)
- [ ] Dynamic type sizing supported
- [ ] "Reduce Motion" accessibility setting respected

## Components

- [ ] All components use the generated tokens
- [ ] Components match their web counterparts visually
- [ ] Component variants are consistent
- [ ] All components have snapshot tests in both light and dark mode

## Documentation

- [ ] Updated design system documentation reflects the new token system
- [ ] Migration examples included in the documentation
- [ ] Developers understand the purpose and usage of the token system

## Verification Steps

1. Run SwiftLint to detect any remaining deprecated styling usage:
   ```bash
   cd ios/ptchampion && swiftlint
   ```

2. Run snapshot tests to verify visual consistency:
   ```bash
   cd ios && fastlane snapshots
   ```

3. Test the app with the following accessibility settings enabled:
   - Dark mode
   - Larger text sizes (Settings > Accessibility > Display & Text Size > Larger Text)
   - Reduce Motion (Settings > Accessibility > Motion > Reduce Motion)

4. Compare UI screens with web counterparts to ensure visual parity

## Final Items

- [ ] All deprecated color and typography definitions marked with `@available(*, deprecated, message: "Use GeneratedColors.xyz instead")`
- [ ] Swift Package documentation updated
- [ ] PR created with before/after screenshots 