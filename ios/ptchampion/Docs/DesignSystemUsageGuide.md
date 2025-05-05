# PT Champion Design System Usage Guide

This guide explains how to use the PTDesignSystem components to maintain a consistent look and feel throughout the PT Champion app.

## Recent Improvements

We've made several enhancements to improve consistency and user experience:

1. **Enhanced Text Fields**: Added focus highlighting to text fields with a golden accent border that appears when the field receives focus.

2. **Component Standardization**: Replaced all instances of native SwiftUI Button, Text, and TextField components with PTButton, PTLabel and PTTextField/FocusableTextField.

3. **Navigation Integration**: Improved how PTButton works within NavigationLink for more consistent behavior.

4. **Loading States**: Standardized loading indicators across the app to use PTButton's built-in loading state.

5. **Form Field Enhancement**: Added appropriate icons to form fields and standardized validation message displays.

These improvements ensure a more cohesive user experience and make future UI updates easier to implement.

## Core Components

### PTButton

Always use `PTButton` for actions instead of SwiftUI's standard `Button`:

```swift
// ✅ CORRECT
PTButton("Save Changes") {
    saveData()
}

// Alternative style variants
PTButton("Secondary Action", style: .secondary) { ... }
PTButton("Outline Action", style: .outline) { ... }
PTButton("Ghost Action", style: .ghost) { ... }
PTButton("Destructive Action", style: .destructive) { ... }

// Size variants
PTButton("Small Button", size: .small) { ... }
PTButton("Large Button", size: .large) { ... }

// With icon
PTButton("Add Item", icon: Image(systemName: "plus")) { ... }

// Full width button
PTButton("Full Width", fullWidth: true) { ... }

// Loading state
PTButton("Saving...", isLoading: isInProgress) { ... }

// ❌ INCORRECT - don't use standard Button
Button("Save Changes") {
    saveData()
}
.padding()
.background(AppTheme.GeneratedColors.brassGold)
.foregroundColor(.white)
.cornerRadius(8)
```

### PTLabel

Use `PTLabel` for text elements instead of SwiftUI's `Text`:

```swift
// ✅ CORRECT
PTLabel("Heading Text", style: .heading)
PTLabel("Subheading Text", style: .subheading)
PTLabel("Body Text", style: .body)
PTLabel("Bold Body Text", style: .bodyBold)
PTLabel("Caption Text", style: .caption)

// Custom size
PTLabel("Custom Size", style: .body, size: .small)

// ❌ INCORRECT - don't use standard Text with manual styling
Text("Heading Text")
    .font(AppTheme.GeneratedTypography.heading())
    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
```

### PTTextField

Use `PTTextField` for input fields:

```swift
// ✅ CORRECT
PTTextField("Enter username", text: $username)

// With label
PTTextField("Email address", text: $email, label: "Email")

// With icon
PTTextField("Password", text: $password, isSecure: true, icon: Image(systemName: "lock"))

// Validation states
textField.validationState(.valid)
textField.validationState(.invalid(message: "Invalid input"))
```

### FocusableTextField

For text fields that need focus highlighting, use our `FocusableTextField` component which enhances `PTTextField` with a focus ring:

```swift
// ✅ CORRECT
FocusableTextField(
    "Email",
    text: $email,
    keyboardType: .emailAddress,
    icon: Image(systemName: "envelope")
)

// Alternatively, use the extension method on PTTextField
@FocusState private var isFieldFocused: Bool

PTTextField("Username", text: $username)
    .withFocusRing($isFieldFocused)
```

### PTCard

Use `PTCard` for card containers:

```swift
// ✅ CORRECT
PTCard {
    VStack {
        PTLabel("Card Title", style: .bodyBold)
        PTLabel("Card content goes here", style: .body)
    }
    .padding(AppTheme.GeneratedSpacing.medium)
}

// ❌ INCORRECT - don't create custom card styling
VStack {
    Text("Card Title")
    Text("Card content")
}
.padding()
.background(Color.white)
.cornerRadius(12)
.shadow(radius: 2)
```

### PTSeparator

Use `PTSeparator` instead of custom dividers:

```swift
// ✅ CORRECT
PTSeparator()

// Customized
PTSeparator(color: AppTheme.GeneratedColors.textTertiary.opacity(0.3))

// ❌ INCORRECT - don't use standard Divider or custom separators
Divider()
    .background(Color.gray.opacity(0.5))
```

## Design Tokens

Always use the design tokens rather than hardcoded values:

### Colors

```swift
// ✅ CORRECT
.foregroundColor(AppTheme.GeneratedColors.textPrimary)
.background(AppTheme.GeneratedColors.cardBackground)

// ❌ INCORRECT - don't use direct color values
.foregroundColor(Color.black)
.background(Color(hex: "#F4F1E6"))
```

### Typography

```swift
// ✅ CORRECT
.font(AppTheme.GeneratedTypography.heading())
.font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.small))

// ❌ INCORRECT - don't use direct font definitions
.font(.system(size: 24, weight: .bold))
.font(Font.custom("BebasNeue-Bold", size: 24))
```

### Spacing

```swift
// ✅ CORRECT
.padding(AppTheme.GeneratedSpacing.medium)
VStack(spacing: AppTheme.GeneratedSpacing.itemSpacing) { ... }

// ❌ INCORRECT - don't use hardcoded spacing values
.padding(16)
VStack(spacing: 8) { ... }
```

### Border Radius

```swift
// ✅ CORRECT
.cornerRadius(AppTheme.GeneratedRadius.card)
RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.medium)

// ❌ INCORRECT - don't use hardcoded radius values
.cornerRadius(12)
RoundedRectangle(cornerRadius: 8)
```

## Navigation and Links

For NavigationLinks, style the button component separately:

```swift
// ✅ CORRECT
NavigationLink(destination: DetailView()) {
    PTButton("View Details", icon: Image(systemName: "chevron.right")) {}
}
.buttonStyle(PlainButtonStyle()) // Remove NavigationLink styling

// For icon-based navigation
NavigationLink(destination: SettingsView()) {
    Image(systemName: "gear")
        .font(.title2)
        .foregroundColor(AppTheme.GeneratedColors.brassGold)
}
```

## Benefits of Using the Design System

1. **Consistency**: Ensures uniform appearance across the app
2. **Adaptability**: Components automatically adjust to light/dark mode
3. **Accessibility**: Pre-built components follow accessibility best practices
4. **Maintainability**: Makes design changes easier to implement app-wide
5. **Development Speed**: Reduces the need to recreate common components

## Migrating Existing Code

When updating existing views, follow this approach:

1. Replace standard SwiftUI `Button` with `PTButton`
2. Replace `Text` with `PTLabel`
3. Replace `TextField` and `SecureField` with `PTTextField` or `FocusableTextField`
4. Replace custom card layouts with `PTCard`
5. Replace hardcoded spacing and style values with design tokens

Always ensure your UI adheres to the PT Champion aesthetics by using the provided components and tokens. 