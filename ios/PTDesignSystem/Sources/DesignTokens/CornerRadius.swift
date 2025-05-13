import SwiftUI

// Corner Radius tokens for the design system
public enum CornerRadius {
    public static let none: CGFloat = 0
    public static let xs: CGFloat = 2
    public static let sm: CGFloat = 4
    public static let md: CGFloat = 6
    public static let lg: CGFloat = 8
    public static let xl: CGFloat = 12
    public static let xxl: CGFloat = 16
    public static let xxxl: CGFloat = 24
    public static let full: CGFloat = 9999
    
    // Legacy aliases for backward compatibility
    public static let card = xl
    public static let panel = xxl
    public static let button = lg
    public static let input = lg
    public static let small = xs
    public static let medium = md
    public static let large = xl
    public static let badge = xs
} 