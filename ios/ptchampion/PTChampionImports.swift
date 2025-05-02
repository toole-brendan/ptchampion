import SwiftUI
import Foundation
import Combine
import UIKit
import SwiftData

/* 
This file provides a common way to import shared types across the app.
Import this file in any Swift file that needs access to shared constants,
styles, or other common definitions.

IMPORTANT: DO NOT define duplicate models here. Instead, import and re-export
the actual model files to ensure there's only one definition of each type.
*/

// Re-export all the model types to make them available
// Note: The actual definitions should be in their respective files

// DO NOT define duplicate models here - use imports instead
// No duplicate User model
// No duplicate WorkoutResultSwiftData model 
// No duplicate AuthViewModel
// No duplicate views

// Re-export the AppTheme and AppConstants for convenient access
// @_exported import struct AppTheme
// @_exported import struct AppConstants

// Prevent SwiftUI Color extensions to avoid color redeclarations
// Colors should only be accessed through AppTheme.Colors

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