import SwiftUI
import DesignTokens

// MARK: - All public typealiases for the design system

// Color alias is now centralized in PTDesignSystem module
// public typealias DSColor = DesignTokens.Color

// Global alias so we can refer to design token colors without colliding with SwiftUI.Color
public typealias DSColor = DesignTokens.ThemeColor 