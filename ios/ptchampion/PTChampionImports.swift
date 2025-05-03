import SwiftUI
import Foundation
import Combine
import UIKit
import SwiftData

/* 
This file provides a common way to import shared types across the app.
Import this file in any Swift file that needs access to shared constants,
styles, or other common definitions.

IMPORTANT: The design system has been updated to use the generated theme from the design-tokens pipeline.
Please use AppTheme.GeneratedColors, AppTheme.GeneratedTypography, etc. instead of the deprecated
AppTheme.Colors, AppTheme.Typography, etc.
*/

// Re-export all the model types to make them available
// Note: The actual definitions should be in their respective files

// DO NOT define duplicate models here - use imports instead
// No duplicate User model
// No duplicate WorkoutResultSwiftData model 
// No duplicate AuthViewModel
// No duplicate views

// Import the generated theme
@_exported import SwiftUI
@_exported import enum AppTheme.GeneratedColors
@_exported import enum AppTheme.GeneratedTypography
@_exported import enum AppTheme.GeneratedRadius
@_exported import enum AppTheme.GeneratedSpacing
@_exported import enum AppTheme.GeneratedShadows

// Re-export the AppTheme and AppConstants for convenient access
// @_exported import enum Theme.AppTheme
// @_exported import struct AppConstants

// Prevent SwiftUI Color extensions to avoid color redeclarations
// Colors should only be accessed through AppTheme.GeneratedColors

// Removed conflicting Color hex helper - use the one in AppTheme or LegacyTheme if needed

// Removed legacy style extensions - Use AppTheme versions
// extension View {
//     public func headingStyle() -> some View { ... }
//     public func subheadingStyle() -> some View { ... }
//     public func labelStyle() -> some View { ... }
//     public func statsNumberStyle() -> some View { ... }
//     public func cardStyle() -> some View { ... }
// }

// Removed legacy button style - Use AppTheme versions
// public struct PrimaryButtonStyle: ButtonStyle { ... } 