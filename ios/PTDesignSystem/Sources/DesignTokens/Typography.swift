import SwiftUI

// Typography tokens for the design system
public enum Typography {
    // Font sizes in points (converted from rem)
    public static let xs: CGFloat = 12
    public static let sm: CGFloat = 14
    public static let base: CGFloat = 16
    public static let lg: CGFloat = 18
    public static let xl: CGFloat = 20
    public static let xxl: CGFloat = 24
    public static let xxxl: CGFloat = 30
    public static let xxxxl: CGFloat = 36
    public static let xxxxxl: CGFloat = 48
    public static let xxxxxxl: CGFloat = 60
    
    // Typography styles matching web
    public static let h1 = Font.futuraBold(size: 36)
    public static let h2 = Font.futuraBold(size: 30)
    public static let h3 = Font.futuraDemi(size: 24)
    public static let h4 = Font.futuraDemi(size: 20)
    public static let h5 = Font.futuraDemi(size: 18)
    public static let h6 = Font.futuraDemi(size: 16)
    public static let bodyLarge = Font.futuraBook(size: 18)
    public static let body = Font.futuraBook(size: 16)
    public static let bodySmall = Font.futuraBook(size: 14)
    public static let caption = Font.futuraBook(size: 12)
    public static let label = Font.futuraMedium(size: 14)
    public static let button = Font.futuraDemi(size: 14)
    public static let monospace = Font.webMonospace()
    
    // Legacy aliases for backward compatibility
    public static let heading1 = h1
    public static let heading2 = h2
    public static let heading3 = h3
    public static let heading4 = h4
    public static let heading = h3  // Default heading size
    public static let small = bodySmall
    public static let tiny = caption
} 