# Manual Styling Cleanup Guide

This guide provides concrete examples for manually cleaning up the remaining legacy styling references.

## 1. PTCard → .card() Modifier (28 remaining)

PTCard typically appears in two patterns:

### Pattern A: Simple wrapper
```swift
// BEFORE
PTCard {
    VStack(alignment: .leading, spacing: 12) {
        Text("Title")
        Text("Subtitle")
    }
    .padding()
}

// AFTER
VStack(alignment: .leading, spacing: 12) {
    Text("Title")
    Text("Subtitle")
}
.padding()
.card()  // New modifier
```

### Pattern B: With parameters
```swift
// BEFORE
PTCard(cornerRadius: 8, shadowRadius: 2) {
    HStack { /* content */ }
}

// AFTER
HStack { /* content */ }
.card()  // New modifier handles shadows and corner radius
```

## 2. AppTheme References → New Tokens (340 remaining)

### Colors
```swift
// BEFORE
Color: AppTheme.GeneratedColors.textPrimary
Background: AppTheme.GeneratedColors.background
Border: AppTheme.GeneratedColors.brassGold

// AFTER
Color: Color.textPrimary
Background: Color.background
Border: Color.brassGold
```

### Spacing
```swift
// BEFORE
.padding(AppTheme.GeneratedSpacing.contentPadding)
.frame(height: AppTheme.GeneratedSpacing.large)
HStack(spacing: AppTheme.GeneratedSpacing.itemSpacing)

// AFTER
.padding(Spacing.contentPadding)
.frame(height: Spacing.large)
HStack(spacing: Spacing.itemSpacing)
```

### Radius
```swift
// BEFORE
.cornerRadius(AppTheme.GeneratedRadius.medium)
.clipShape(RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.button))

// AFTER
.cornerRadius(CornerRadius.medium)
.clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
```

### Typography
```swift
// BEFORE
.font(AppTheme.GeneratedTypography.heading(size: AppTheme.GeneratedTypography.heading1))
.font(AppTheme.GeneratedTypography.bodySemibold())
.font(AppTheme.GeneratedTypography.caption())

// AFTER
.heading1()
.bodySemibold()
.caption()
```

## 3. Adding Container Modifiers to Main Views

For layouts with ScrollView:
```swift
// BEFORE
ScrollView {
    VStack(spacing: 16) {
        // View content...
    }
    .padding()
}

// AFTER
ScrollView {
    VStack(spacing: 16) {
        // View content...
    }
    .padding()
}
.container()  // Add at this level, AFTER the ScrollView
```

For layouts without ScrollView:
```swift
// BEFORE
VStack(alignment: .leading) {
    // View content...
}
.padding()

// AFTER
VStack(alignment: .leading) {
    // View content...
}
.padding()
.container()  // Add at this level, AFTER the root VStack
```

## 4. Workflow for Manual Cleanup

1. Start with one file at a time, focusing on the list in the migration report
2. Scan for marked TODOs from our script
3. For each file:
   - Replace PTCard with .card()
   - Replace AppTheme references with their new equivalents
   - Add .container() to main screen layouts
4. Run the migration script after each batch of changes to see progress:
   ```bash
   bash ios/complete_styling_migration.sh
   ```
5. Build and test the app after significant changes 