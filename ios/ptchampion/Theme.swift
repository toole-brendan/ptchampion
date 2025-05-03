import Foundation
import SwiftUI

// Re-export the AppTheme type for module-like imports
@_exported import struct ptchampion.Theme.AppTheme 

// Export AppTheme for use in the app
@_exported import enum AppTheme 

// Make sure the GeneratedColors, etc. are accessible
@_exported import enum AppTheme.GeneratedColors
@_exported import enum AppTheme.GeneratedTypography
@_exported import enum AppTheme.GeneratedRadius
@_exported import enum AppTheme.GeneratedSpacing
@_exported import enum AppTheme.GeneratedShadows 