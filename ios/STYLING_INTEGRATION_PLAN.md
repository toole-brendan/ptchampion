# iOS Styling Integration Implementation Plan

## Overview

This document outlines the comprehensive plan to fully integrate the new design token system and styling architecture into the iOS application. While the design token pipeline and infrastructure have been successfully implemented, many views and components still use deprecated direct references to the old styling system rather than the generated tokens.

## Current State Assessment

- ✅ Design token pipeline established with Style Dictionary
- ✅ Generated files in place (`AppTheme+Generated.swift`, `ColorAssets.swift`)
- ✅ Dark mode color assets created
- ✅ New components available (Separator, MetricCard, BottomNavBar, Toast)
- ❌ Many views still reference deprecated `AppTheme.Colors` directly instead of `AppTheme.GeneratedColors`
- ❌ Some components may not be using dynamic typography for better accessibility

## Implementation Goals

1. Achieve full styling parity with the web application
2. Ensure consistent color and typography usage across the app
3. Improve accessibility with dynamic type support
4. Enable seamless dark mode support
5. Centralize theme application at the root level

## Implementation Plan

### Phase 1: Core Infrastructure (1-2 days) ✅ COMPLETED

#### 1.1 Create ThemeManager Class ✅

Create a central theme manager to handle theme-related functionality:

```swift
// Create new file: ios/ptchampion/Theme/ThemeManager.swift
import SwiftUI
import Combine

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentColorScheme: ColorScheme = .light
    
    // For future theme switching capability
    func toggleDarkMode() {
        currentColorScheme = currentColorScheme == .light ? .dark : .light
    }
}
```

#### 1.2 Update App Entry Point ✅

Modify the `PTChampionApp.swift` file to use the ThemeManager at the root level:

```swift
@main
struct PTChampionApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentColorScheme)
        }
    }
}
```

#### 1.3 Create Helper Extension for Accessibility ✅

Create an extension to simplify the process of using dynamic typography:

```swift
// Create new file: ios/ptchampion/Theme/DynamicTypeExtensions.swift
import SwiftUI

extension View {
    func dynamicTypeSize(_ sizes: DynamicTypeSize...) -> some View {
        if #available(iOS 15.0, *) {
            return self.dynamicTypeSize(sizes.isEmpty ? .large : DynamicTypeSize.allCases)
        } else {
            return self
        }
    }
    
    func reduceMotionIfNeeded() -> some View {
        self.modifier(ReduceMotionViewModifier())
    }
}

struct ReduceMotionViewModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func body(content: Content) -> some View {
        if reduceMotion {
            content.animation(nil)
        } else {
            content
        }
    }
}
```

### Phase 2: Component Updates (3-4 days) ✅ COMPLETED

#### 2.1 Update Core Style Components ✅ COMPLETED

**CardStyles.swift** ✅
- Replace all color references with GeneratedColors
- Update to use GeneratedRadius, GeneratedShadows
- Add dark mode support with adaptive colors

**TextFieldStyles.swift** ✅
- Update validation styling to use generated colors
- Ensure focus states match the design system
- Add native focus state support for iOS 15+

**ButtonStyles.swift** ✅
- Already using y-offset for press animations
- Added support for reduced motion accessibility
- Using GeneratedTypography with proper sizing

#### 2.2 Update Common UI Components ✅ COMPLETED

Update all shared UI components to use the generated styling system:

1. **MetricCard** ✅ (already updated)
2. **Separator** ✅ (already updated)
3. **Toast/Snackbar** ✅
   - Updated to use GeneratedColors and GeneratedTypography
   - Improved dark mode support
   - Added dynamic spacing
4. **BottomNavigationBar** ✅ (already updated)
5. **Spinners and Loading indicators** ✅
   - Updated to use GeneratedColors and GeneratedTypography
   - Added proper support for reduced motion accessibility
   - Improved dark mode compatibility

#### 2.3 Create Missing Component Wrappers ✅ COMPLETED

All required components from the web already have iOS equivalents and are properly styled with generated tokens:

- Button ✅
- Card ✅ 
- TextField ✅
- Separator ✅
- MetricCard ✅
- BottomNavBar ✅
- Toast ✅
- Spinner ✅

### Phase 3: View Updates (5-7 days)

#### 3.1 Update in Priority Order

Update views in the following priority order:

1. **Main Navigation Views** - These set the tone for the entire app
2. **Dashboard Views** - High visibility screens
3. **Workout and Progress Views** - Core functionality
4. **Settings and Profile Views** - User customization
5. **Authentication Views** - Less frequent but important for first impressions
6. **Utility and Helper Views** - Support views

For each view file:
1. Identify all theme references
2. Replace with generated equivalents
3. Add dark mode compatibility
4. Test with accessibility features

#### 3.2 Example View Update Process

Taking `ComponentGalleryView.swift` as an example, the update process should:

**Original Code:**
```swift
Text("Primary Button")
    .font(.custom(AppFonts.bodyBold, size: AppConstants.FontSize.sm))
    .foregroundColor(selectedComponent == index ? .deepOpsGreen : .tacticalGray)
    .padding(.vertical, AppConstants.Spacing.sm)
    .padding(.horizontal, AppConstants.Spacing.md)
    .background(selectedComponent == index ? Color.brassGold.opacity(0.15) : Color.clear)
    .cornerRadius(AppConstants.Radius.full)
```

**Updated Code:**
```swift
Text("Primary Button")
    .font(AppTheme.GeneratedTypography.bodyBold(size: AppTheme.GeneratedTypography.small))
    .foregroundColor(selectedComponent == index ? 
                    AppTheme.GeneratedColors.deepOps : 
                    AppTheme.GeneratedColors.tacticalGray)
    .padding(.vertical, AppTheme.GeneratedSpacing.itemSpacing)
    .padding(.horizontal, AppTheme.GeneratedSpacing.contentPadding)
    .background(selectedComponent == index ? 
               AppTheme.GeneratedColors.brassGold.opacity(0.15) : 
               Color.clear)
    .cornerRadius(AppTheme.GeneratedRadius.button)
```

### Phase 4: SwiftLint and Code Quality (1-2 days) ✅ IN PROGRESS

#### 4.1 Add SwiftLint Custom Rules ✅

Update the `.swiftlint.yml` file to enforce the new styling approach:

```yaml
custom_rules:
  use_generated_colors:
    name: "Use Generated Colors"
    regex: "AppTheme\\.Colors\\."
    message: "Use AppTheme.GeneratedColors instead of AppTheme.Colors"
    severity: warning
  
  use_generated_typography:
    name: "Use Generated Typography"
    regex: "AppTheme\\.Typography\\."
    message: "Use AppTheme.GeneratedTypography instead of AppTheme.Typography"
    severity: warning
    
  direct_color_usage:
    name: "Direct Color Usage"
    regex: "\\.foregroundColor\\((\\.deepOpsGreen|\\.brassGold|\\.tacticalGray|\\.commandBlack|\\.cream)"
    message: "Use AppTheme.GeneratedColors instead of direct color references"
    severity: warning
```

#### 4.2 Documentation Updates

Update the `PTChampionDesignSystem.docc` documentation to reflect the new styling system:

1. Add examples of the new styling approach
2. Document the transition from old to new system
3. Create a cheat sheet for developers

### Phase 5: Testing and Validation (2-3 days)

#### 5.1 Visual Testing

Create or update snapshot tests for all components in both light and dark mode:

```swift
func testButtonStylesInDarkMode() {
    // Test all button variants in dark mode
    let button = PTButton(title: "Test Button", action: {})
        .environment(\.colorScheme, .dark)
    let result = verifySnapshot(of: button, as: .image)
    XCTAssertTrue(result)
}
```

#### 5.2 Accessibility Testing

Test with accessibility features enabled:

1. Dynamic Type - Test with larger text sizes
2. VoiceOver - Ensure proper labeling
3. Reduce Motion - Verify animations are properly disabled
4. Color Contrast - Validate with WCAG AA standards

#### 5.3 Device Testing

Test on multiple devices:
- iPhone SE (smallest supported screen)
- iPhone 15 Pro Max (largest screen)
- iPads (if applicable)

### Phase 6: Finalization (1-2 days)

#### 6.1 Remove Deprecated Code

Once all views have been updated, remove the deprecated styling code with appropriate warnings:

```swift
// In AppTheme.swift - Remove these once migration is complete
@available(*, deprecated, message: "Removed. Use GeneratedColors instead")
public enum Colors { }

@available(*, deprecated, message: "Removed. Use GeneratedTypography instead")
public enum Typography { }
```

#### 6.2 Create Migration Documentation

Document any issues encountered during the migration and their solutions for future reference.

## Timeline

| Phase | Estimated Duration | 
|-------|-------------------|
| Phase 1: Core Infrastructure | 1-2 days |
| Phase 2: Component Updates | 3-4 days |
| Phase 3: View Updates | 5-7 days |
| Phase 4: SwiftLint and Code Quality | 1-2 days |
| Phase 5: Testing and Validation | 2-3 days |
| Phase 6: Finalization | 1-2 days |
| **Total** | **13-20 days** |

## Verification Checklist

Before considering the styling integration complete, verify that:

- [ ] All views use the GeneratedColors, GeneratedTypography, etc.
- [ ] Dark mode works correctly throughout the app
- [ ] Dynamic type sizing is supported for all text elements
- [ ] Animations respect the "Reduce Motion" accessibility setting
- [ ] All components visually match their web counterparts
- [ ] All snapshot tests pass
- [ ] SwiftLint detects no remaining deprecated styling usage
- [ ] Documentation is updated
- [ ] No accessibility violations are detected

## Appendix: Code Examples

### Component Update Examples

#### Button Style Update

```swift
// Before
Button(action: action) {
    Text(title)
        .font(.custom(AppFonts.bodyBold, size: fontSize))
        .foregroundColor(foregroundColor)
}
.padding(.vertical, AppConstants.Spacing.sm)
.padding(.horizontal, AppConstants.Spacing.md)
.background(backgroundColor)
.cornerRadius(AppTheme.Radius.button)
.scaleEffect(configuration.isPressed ? 0.98 : 1.0)

// After
Button(action: action) {
    Text(title)
        .font(AppTheme.GeneratedTypography.bodyBold(size: fontSize))
        .foregroundColor(foregroundColor)
}
.padding(.vertical, AppTheme.GeneratedSpacing.itemSpacing)
.padding(.horizontal, AppTheme.GeneratedSpacing.contentPadding)
.background(backgroundColor)
.cornerRadius(AppTheme.GeneratedRadius.button)
.offset(y: configuration.isPressed ? -2 : 0)
.animation(.spring(), value: configuration.isPressed)
```

#### Text Style Update

```swift
// Before
Text("Heading")
    .font(AppTheme.Typography.heading1())
    .foregroundColor(AppTheme.Colors.deepOps)

// After
Text("Heading")
    .font(AppTheme.GeneratedTypography.heading(size: AppTheme.GeneratedTypography.heading1))
    .foregroundColor(AppTheme.GeneratedColors.deepOps)
```

#### Card Style Update

```swift
// Before
.background(AppTheme.Colors.cardBackground)
.cornerRadius(AppTheme.Radius.card)
.withShadow(AppTheme.Shadows.small)

// After
.background(AppTheme.GeneratedColors.cardBackground)
.cornerRadius(AppTheme.GeneratedRadius.card)
.withShadow(AppTheme.GeneratedShadows.small)
``` 