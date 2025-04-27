import SwiftUI

// Main app constants
enum AppConstants {
    // Global padding used throughout the app
    static let globalPadding: CGFloat = 16
    
    // Spacing between cards in stack views
    static let cardGap: CGFloat = 12
    
    // Re-export the constants from Theme.swift to avoid duplication
    typealias Spacing = Theme.AppConstants.Spacing
    typealias Radius = Theme.AppConstants.Radius
    typealias FontSize = Theme.AppConstants.FontSize
    typealias Animation = Theme.AppConstants.Animation
    typealias DistanceUnit = Theme.AppConstants.DistanceUnit
} 