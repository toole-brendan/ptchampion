import SwiftUI

// Main app constants
public enum AppConstants {
    // Global padding used throughout the app
    public static let globalPadding: CGFloat = 16
    
    // Spacing between cards in stack views
    public static let cardGap: CGFloat = 12
    
    // These constants are now defined directly in AppTheme
    // Reference AppTheme for spacing, radius, font size, and animation constants
    public typealias Spacing = AppTheme.Spacing
    public typealias Radius = AppTheme.Radius
    public typealias FontSize = AppTheme.Typography
    public typealias Animation = AppTheme.Animation
    public typealias DistanceUnit = AppTheme.DistanceUnit
} 