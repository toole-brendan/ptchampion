import SwiftUI
import Foundation
import Combine
import UIKit

/* 
This file provides a common way to import shared types across the app.
Import this file in any Swift file that needs access to shared constants,
styles, or other common definitions.

IMPORTANT: This file should be imported by all Swift files in the project
that need access to the app's shared types.
*/

// This file ensures all necessary types are available throughout the app
// Import this file in any Swift file that needs access to shared types like AppConstants

// Re-export the AppTheme and AppConstants for convenient access
// No module prefix needed since these are in the same module
@_exported import struct AppTheme
@_exported import struct AppConstants

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