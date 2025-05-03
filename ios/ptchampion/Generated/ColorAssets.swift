import SwiftUI

/// Extension to Color that adds support for loading from the GeneratedColors folder
extension Color {
    /// Load a color from the GeneratedColors folder
    /// - Parameter name: The name of the color asset
    /// - Returns: A Color instance
    static func generatedColor(_ name: String) -> Color {
        // Use this path to locate the color in GeneratedColors folder
        return Color("GeneratedColors/\(name)")
    }
}

/// Update the GeneratedColors implementation to use the new assets folder
extension AppTheme.GeneratedColors {
    // Override the static properties to use the GeneratedColors folder
    public static let cream = Color.generatedColor("Cream")
    public static let creamDark = Color.generatedColor("CreamDark")
    public static let deepOps = Color.generatedColor("DeepOps")
    public static let brassGold = Color.generatedColor("BrassGold")
    public static let armyTan = Color.generatedColor("ArmyTan")
    public static let oliveMist = Color.generatedColor("OliveMist")
    public static let commandBlack = Color.generatedColor("CommandBlack")
    public static let tacticalGray = Color.generatedColor("TacticalGray")
    public static let success = Color.generatedColor("Success")
    public static let warning = Color.generatedColor("Warning")
    public static let error = Color.generatedColor("Error")
    public static let info = Color.generatedColor("Info")
    
    // Semantic colors
    public static let primary = Color.generatedColor("Primary")
    public static let secondary = Color.generatedColor("Secondary")
    public static let textPrimary = Color.generatedColor("TextPrimary")
    public static let textSecondary = Color.generatedColor("TextSecondary")
    public static let textTertiary = Color.generatedColor("TextTertiary")
    public static let background = Color.generatedColor("Background")
    public static let cardBackground = Color.generatedColor("CardBackground")
} 