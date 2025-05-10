# Profile & Settings Module

This module handles the user profile display and settings management for PT Champion.

## Architecture

The Profile module follows a modular design pattern where each component has a single responsibility:

```
Profile Module
├── ProfileView.swift              # Main container view that assembles all components
├── ProfileHeaderView.swift        # User avatar, name, email, and edit button
├── ProfilePreferencesView.swift   # Quick access preferences (units, notifications)
├── AccountActionsView.swift       # Account actions (change password, logout, delete account)
├── MoreActionsView.swift          # Additional options (privacy policy, connected devices)
├── AppInfoView.swift              # App version information
├── EditProfileView.swift          # Form for editing profile information
└── SettingsView.swift             # Full settings screen
```

## Component Responsibilities

### ProfileView
- Acts as a container that assembles all subcomponents
- Manages navigation and modal presentation
- Provides the AuthViewModel to child components via EnvironmentObject

### ProfileHeaderView
- Displays user avatar, name, and email
- Provides button to open EditProfileView

### ProfilePreferencesView (formerly ProfileSettingsSectionView)
- Quick access to basic preferences with toggles and pickers
- Uses AppStorage for persistence
- Includes unit settings and notification toggles

### AccountActionsView
- Contains buttons for account-related actions
- Handles logout functionality
- Provides change password and delete account options

### MoreActionsView
- Contains buttons for additional features
- Handles privacy policy and connected devices navigation

### AppInfoView
- Simple component that displays the app version

### EditProfileView
- Modal form for editing user profile information
- Handles validation and submission of profile updates

### SettingsView
- Comprehensive settings screen with grouped settings
- Includes appearance, units, notifications, and device management
- Accessible via the gear icon in ProfileView

## State Management

- **AuthViewModel**: Central view model that manages authentication state and user data
- **AppStorage**: Used for user preferences (units, appearance, notifications)

## Design System Integration

All components use the PT Design System for consistency:
- AppTheme.GeneratedColors for color tokens
- AppTheme.GeneratedTypography for typography
- AppTheme.GeneratedSpacing for spacing
- PTCard and other design system components for UI elements

## Usage

The ProfileView is typically used as a tab in the main TabView of the app. It automatically receives the AuthViewModel via EnvironmentObject. 