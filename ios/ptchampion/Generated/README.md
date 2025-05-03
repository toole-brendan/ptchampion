# Generated Design System

This directory contains generated design system files for the PT Champion app. These files are generated from the design-tokens pipeline and should not be manually edited.

## Migration Guide

When using the design system in your code, you should use the generated theme components instead of the old ones:

### Colors

**Old way:**
```swift
Text("Hello")
    .foregroundColor(AppTheme.Colors.deepOps)
```

**New way:**
```swift
Text("Hello")
    .foregroundColor(AppTheme.GeneratedColors.deepOps)
```

### Typography

**Old way:**
```swift
Text("Hello")
    .font(AppTheme.Typography.heading1())
```

**New way:**
```swift
Text("Hello")
    .font(AppTheme.GeneratedTypography.heading1())
```

### Radius

**Old way:**
```swift
RoundedRectangle(cornerRadius: AppTheme.Radius.card)
```

**New way:**
```swift
RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.card)
```

### Spacing

**Old way:**
```swift
.padding(.horizontal, AppTheme.Spacing.contentPadding)
```

**New way:**
```swift
.padding(.horizontal, AppTheme.GeneratedSpacing.contentPadding)
```

### Shadows

**Old way:**
```swift
.withShadow(AppTheme.Shadows.small)
```

**New way:**
```swift
.withShadow(AppTheme.GeneratedShadows.small)
```

## Full Component Migration

Components should be updated to use the generated theme. For example:

**Old way:**
```swift
struct MyView: View {
    var body: some View {
        Text("Hello")
            .font(AppTheme.Typography.heading1())
            .foregroundColor(AppTheme.Colors.deepOps)
            .padding(AppTheme.Spacing.contentPadding)
            .background(AppTheme.Colors.background)
            .cornerRadius(AppTheme.Radius.card)
            .withShadow(AppTheme.Shadows.small)
    }
}
```

**New way:**
```swift
struct MyView: View {
    var body: some View {
        Text("Hello")
            .font(AppTheme.GeneratedTypography.heading1())
            .foregroundColor(AppTheme.GeneratedColors.deepOps)
            .padding(AppTheme.GeneratedSpacing.contentPadding)
            .background(AppTheme.GeneratedColors.background)
            .cornerRadius(AppTheme.GeneratedRadius.card)
            .withShadow(AppTheme.GeneratedShadows.small)
    }
}
``` 