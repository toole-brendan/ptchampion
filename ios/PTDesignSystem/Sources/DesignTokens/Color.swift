import SwiftUI

// Color tokens for the design system
public enum ThemeColor {
    // Brand palette
    public static let brand50 = SwiftUI.Color(hex: "f0f9ff")
    public static let brand100 = SwiftUI.Color(hex: "e0f2fe")
    public static let brand200 = SwiftUI.Color(hex: "bae6fd")
    public static let brand300 = SwiftUI.Color(hex: "7dd3fc")
    public static let brand400 = SwiftUI.Color(hex: "38bdf8")
    public static let brand500 = SwiftUI.Color(hex: "0ea5e9")
    public static let brand600 = SwiftUI.Color(hex: "0284c7")
    public static let brand700 = SwiftUI.Color(hex: "0369a1")
    public static let brand800 = SwiftUI.Color(hex: "075985")
    public static let brand900 = SwiftUI.Color(hex: "0c4a6e")
    public static let brand950 = SwiftUI.Color(hex: "082f49")
    
    // Success palette
    public static let success50 = SwiftUI.Color(hex: "f0fdf4")
    public static let success100 = SwiftUI.Color(hex: "dcfce7")
    public static let success200 = SwiftUI.Color(hex: "bbf7d0")
    public static let success300 = SwiftUI.Color(hex: "86efac")
    public static let success400 = SwiftUI.Color(hex: "4ade80")
    public static let success500 = SwiftUI.Color(hex: "22c55e")
    public static let success600 = SwiftUI.Color(hex: "16a34a")
    public static let success700 = SwiftUI.Color(hex: "15803d")
    public static let success800 = SwiftUI.Color(hex: "166534")
    public static let success900 = SwiftUI.Color(hex: "14532d")
    public static let success950 = SwiftUI.Color(hex: "052e16")
    
    // Warning palette
    public static let warning50 = SwiftUI.Color(hex: "fffbeb")
    public static let warning100 = SwiftUI.Color(hex: "fef3c7")
    public static let warning200 = SwiftUI.Color(hex: "fde68a")
    public static let warning300 = SwiftUI.Color(hex: "fcd34d")
    public static let warning400 = SwiftUI.Color(hex: "fbbf24")
    public static let warning500 = SwiftUI.Color(hex: "f59e0b")
    public static let warning600 = SwiftUI.Color(hex: "d97706")
    public static let warning700 = SwiftUI.Color(hex: "b45309")
    public static let warning800 = SwiftUI.Color(hex: "92400e")
    public static let warning900 = SwiftUI.Color(hex: "78350f")
    public static let warning950 = SwiftUI.Color(hex: "451a03")
    
    // Error palette
    public static let error50 = SwiftUI.Color(hex: "fef2f2")
    public static let error100 = SwiftUI.Color(hex: "fee2e2")
    public static let error200 = SwiftUI.Color(hex: "fecaca")
    public static let error300 = SwiftUI.Color(hex: "fca5a5")
    public static let error400 = SwiftUI.Color(hex: "f87171")
    public static let error500 = SwiftUI.Color(hex: "ef4444")
    public static let error600 = SwiftUI.Color(hex: "dc2626")
    public static let error700 = SwiftUI.Color(hex: "b91c1c")
    public static let error800 = SwiftUI.Color(hex: "991b1b")
    public static let error900 = SwiftUI.Color(hex: "7f1d1d")
    public static let error950 = SwiftUI.Color(hex: "450a0a")
    
    // Gray palette
    public static let gray50 = SwiftUI.Color(hex: "f9fafb")
    public static let gray100 = SwiftUI.Color(hex: "f3f4f6")
    public static let gray200 = SwiftUI.Color(hex: "e5e7eb")
    public static let gray300 = SwiftUI.Color(hex: "d1d5db")
    public static let gray400 = SwiftUI.Color(hex: "9ca3af")
    public static let gray500 = SwiftUI.Color(hex: "6b7280")
    public static let gray600 = SwiftUI.Color(hex: "4b5563")
    public static let gray700 = SwiftUI.Color(hex: "374151")
    public static let gray800 = SwiftUI.Color(hex: "1f2937")
    public static let gray900 = SwiftUI.Color(hex: "111827")
    public static let gray950 = SwiftUI.Color(hex: "030712")
    
    // Semantic colors
    public static let background = SwiftUI.Color(hex: "ffffff")
    public static let backgroundSubtle = SwiftUI.Color(hex: "f9fafb")
    public static let surface = SwiftUI.Color(hex: "ffffff")
    public static let surfaceRaised = SwiftUI.Color(hex: "f9fafb")
    public static let borderDefault = SwiftUI.Color(hex: "e5e7eb")
    public static let borderStrong = SwiftUI.Color(hex: "d1d5db")
    public static let textDefault = SwiftUI.Color(hex: "111827")
    public static let textSubtle = SwiftUI.Color(hex: "6b7280")
    public static let textDisabled = SwiftUI.Color(hex: "9ca3af")
    public static let textInverted = SwiftUI.Color(hex: "ffffff")
    
    // Legacy aliases for backward compatibility
    public static let primary = brand500
    public static let secondary = brand300
    public static let accent = brand700
    public static let cardBackground = surface
    public static let textPrimary = textDefault
    public static let textSecondary = textSubtle
    public static let textTertiary = textDisabled
    
    // PT Champion specific colors
    public static let deepOps = SwiftUI.Color(hex: "2C3E50")
    public static let brassGold = SwiftUI.Color(hex: "D4AF37")
    public static let tacticalGray = SwiftUI.Color(hex: "54595F")
    public static let cream = SwiftUI.Color(hex: "F5F5DC")
    public static let commandBlack = SwiftUI.Color(hex: "111111")
    public static let armyTan = SwiftUI.Color(hex: "CEB888")
    public static let oliveMist = SwiftUI.Color(hex: "666633")
    
    // Status colors
    public static let success = success500
    public static let warning = warning500
    public static let error = error500
    public static let info = brand500
    
    // Text on color backgrounds
    public static let textOnPrimary = textInverted
    public static let textOnSuccess = textInverted
    public static let textOnWarning = textDefault
    public static let textOnError = textInverted
}

// Helper extension to create colors from hex strings
extension SwiftUI.Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 