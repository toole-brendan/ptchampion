import SwiftUI

// Spacing tokens for the design system
public enum Spacing {
    public static let space0: CGFloat = 0
    public static let space1: CGFloat = 4      // 0.25rem
    public static let space2: CGFloat = 8      // 0.5rem
    public static let space3: CGFloat = 12     // 0.75rem
    public static let space4: CGFloat = 16     // 1rem
    public static let space5: CGFloat = 20     // 1.25rem
    public static let space6: CGFloat = 24     // 1.5rem
    public static let space8: CGFloat = 32     // 2rem
    public static let space10: CGFloat = 40    // 2.5rem
    public static let space12: CGFloat = 48    // 3rem
    public static let space16: CGFloat = 64    // 4rem
    public static let space20: CGFloat = 80    // 5rem
    public static let space24: CGFloat = 96    // 6rem
    public static let space32: CGFloat = 128   // 8rem
    public static let space40: CGFloat = 160   // 10rem
    public static let space48: CGFloat = 192   // 12rem
    public static let space56: CGFloat = 224   // 14rem
    public static let space64: CGFloat = 256   // 16rem
    
    // Legacy aliases for backward compatibility
    public static let section = space8
    public static let cardGap = space4
    public static let contentPadding = space4
    public static let itemSpacing = space2
    public static let extraSmall = space1
    public static let small = space2
    public static let medium = space4
    public static let large = space6
} 