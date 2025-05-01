import SwiftUI

// Swift doesn't support relative path imports
// Instead, we'll duplicate the necessary elements for compatibility

// MARK: - Legacy Theme Redirect
// This file exists for backward compatibility
// It redirects to the new AppTheme system for colors and constants

// DO NOT add direct color extensions here - they're already defined in GeneratedAssetSymbols
// and would cause conflicts. Only add non-asset colors if needed.

// Legacy Theme struct now contains duplicated constants for compatibility
public struct Theme {
    public enum AppConstants {
        // For backward compatibility
        public enum FontSize {
            public static let xs: CGFloat = 10
            public static let sm: CGFloat = 12
            public static let md: CGFloat = 14
            public static let lg: CGFloat = 16
            public static let xl: CGFloat = 20
            public static let xxl: CGFloat = 24
            public static let xxxl: CGFloat = 30
            public static let xxxxl: CGFloat = 36
        }
        
        // Spacing (duplicated from AppTheme)
        public enum Spacing {
            public static let xs: CGFloat = 4
            public static let sm: CGFloat = 8
            public static let md: CGFloat = 16
            public static let lg: CGFloat = 24
            public static let xl: CGFloat = 32
            public static let xxl: CGFloat = 48
            public static let xxxl: CGFloat = 64
        }
        
        // Radius (duplicated from AppTheme)
        public enum Radius {
            public static let none: CGFloat = 0
            public static let sm: CGFloat = 4
            public static let md: CGFloat = 8
            public static let lg: CGFloat = 12
            public static let xl: CGFloat = 16
            public static let full: CGFloat = 9999
        }
        
        // Animation Durations (duplicated from AppTheme)
        public enum Animation {
            public static let standard = SwiftUI.Animation.easeInOut(duration: 0.2)
            public static let slow = SwiftUI.Animation.easeInOut(duration: 0.3)
        }
        
        // Enum for distance units (duplicated from AppTheme)
        public enum DistanceUnit: String, Codable, CaseIterable {
            case kilometers = "km"
            case miles = "mi"

            public var id: String { self.rawValue }

            public var displayName: String {
                switch self {
                case .kilometers: return "Kilometers"
                case .miles: return "Miles"
                }
            }

            // Conversion factor from meters
            public func convertFromMeters(_ meters: Double) -> Double {
                switch self {
                case .kilometers: return meters / 1000.0
                case .miles: return meters / 1609.34
                }
            }
        }
    }
} 