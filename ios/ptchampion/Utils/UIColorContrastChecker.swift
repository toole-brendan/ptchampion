import UIKit
import SwiftUI
import PTDesignSystem

/// A utility to check color contrast ratio for WCAG accessibility compliance
public struct UIColorContrastChecker {
    
    /// WCAG 2.1 contrast ratio requirements
    public enum WCAGLevel {
        /// Level AA requires a contrast ratio of at least 4.5:1 for normal text and 3:1 for large text
        case AA
        /// Level AAA requires a contrast ratio of at least 7:1 for normal text and 4.5:1 for large text
        case AAA
        
        func getMinimumRatio(forLargeText: Bool) -> CGFloat {
            switch self {
            case .AA:
                return forLargeText ? 3.0 : 4.5
            case .AAA:
                return forLargeText ? 4.5 : 7.0
            }
        }
    }
    
    /// Calculates the contrast ratio between two colors
    /// - Parameters:
    ///   - color1: The first color
    ///   - color2: The second color
    /// - Returns: The contrast ratio, where 1:1 is no contrast and 21:1 is maximum contrast
    public static func contrastRatio(between color1: UIColor, and color2: UIColor) -> CGFloat {
        let lum1 = luminance(of: color1)
        let lum2 = luminance(of: color2)
        
        let lighter = max(lum1, lum2)
        let darker = min(lum1, lum2)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    /// Checks if the contrast ratio between two colors meets WCAG requirements
    /// - Parameters:
    ///   - color1: The first color
    ///   - color2: The second color
    ///   - level: The WCAG compliance level to check for
    ///   - isLargeText: Whether the text is large (generally 18pt+ or 14pt+ bold)
    /// - Returns: True if the contrast meets the requirements, false otherwise
    public static func meetsContrastRequirements(
        between color1: UIColor,
        and color2: UIColor,
        level: WCAGLevel = .AA,
        isLargeText: Bool = false
    ) -> Bool {
        let ratio = contrastRatio(between: color1, and: color2)
        return ratio >= level.getMinimumRatio(forLargeText: isLargeText)
    }
    
    /// Checks the contrast of a color against the app's theme colors
    /// - Parameters:
    ///   - color: The color to check
    ///   - level: The WCAG compliance level to check for
    ///   - isLargeText: Whether the text is large
    /// - Returns: A dictionary with theme color names as keys and boolean success values
    public static func checkThemeContrast(
        against color: UIColor,
        level: WCAGLevel = .AA,
        isLargeText: Bool = false
    ) -> [String: Bool] {
        // Get UIColors from AppTheme
        let uiDeepOps = UIColor(PTDesignSystem.Color.deepOps)
        let uiBrassGold = UIColor(PTDesignSystem.Color.brassGold)
        let uiCream = UIColor(PTDesignSystem.Color.cream)
        let uiCommandBlack = UIColor(PTDesignSystem.Color.commandBlack)
        let uiTacticalGray = UIColor(PTDesignSystem.Color.tacticalGray)
        
        // Check contrast against each theme color
        return [
            "deepOps": meetsContrastRequirements(between: color, and: uiDeepOps, level: level, isLargeText: isLargeText),
            "brassGold": meetsContrastRequirements(between: color, and: uiBrassGold, level: level, isLargeText: isLargeText),
            "cream": meetsContrastRequirements(between: color, and: uiCream, level: level, isLargeText: isLargeText),
            "commandBlack": meetsContrastRequirements(between: color, and: uiCommandBlack, level: level, isLargeText: isLargeText),
            "tacticalGray": meetsContrastRequirements(between: color, and: uiTacticalGray, level: level, isLargeText: isLargeText)
        ]
    }
    
    /// Calculates the relative luminance of a color for WCAG contrast calculations
    private static func luminance(of color: UIColor) -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let r = transformComponent(red)
        let g = transformComponent(green)
        let b = transformComponent(blue)
        
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
    
    /// Transform a color component according to WCAG formula
    private static func transformComponent(_ component: CGFloat) -> CGFloat {
        return component <= 0.03928 ? 
            component / 12.92 : 
            pow((component + 0.055) / 1.055, 2.4)
    }
    
    /// Converts a SwiftUI Color to UIColor
    public static func UIColorFrom(_ color: SwiftUI.Color) -> UIColor {
        return UIColor(color)
    }
}

// SwiftUI preview extension to visualize contrast ratios
public struct ContrastRatioPreview: View {
    let foreground: SwiftUI.Color
    let background: SwiftUI.Color
    let text: String
    
    @State private var contrastRatio: CGFloat = 0
    @State private var meetsAA: Bool = false
    @State private var meetsAAA: Bool = false
    
    public init(
        foreground: SwiftUI.Color,
        background: SwiftUI.Color,
        text: String = "Sample Text"
    ) {
        self.foreground = foreground
        self.background = background
        self.text = text
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            Text(text)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(foreground)
                .padding()
                .frame(maxWidth: .infinity)
                .background(background)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Contrast Ratio: \(String(format: "%.2f", contrastRatio)):1")
                    .font(.caption)
                
                HStack {
                    Image(systemName: meetsAA ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(meetsAA ? .green : .red)
                    
                    Text("WCAG AA \(meetsAA ? "Pass" : "Fail")")
                        .font(.caption)
                }
                
                HStack {
                    Image(systemName: meetsAAA ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(meetsAAA ? .green : .red)
                    
                    Text("WCAG AAA \(meetsAAA ? "Pass" : "Fail")")
                        .font(.caption)
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            let ratio = UIColorContrastChecker.contrastRatio(
                between: UIColorContrastChecker.UIColorFrom(foreground),
                and: UIColorContrastChecker.UIColorFrom(background)
            )
            
            self.contrastRatio = ratio
            self.meetsAA = ratio >= 4.5
            self.meetsAAA = ratio >= 7.0
        }
        .border(SwiftUI.Color.gray, width: 1)
    }
}

#Preview {
    VStack {
        ContrastRatioPreview(
            foreground: PTDesignSystem.Color.deepOps,
            background: PTDesignSystem.Color.cream,
            text: "DeepOps on Cream"
        )
        
        ContrastRatioPreview(
            foreground: PTDesignSystem.Color.brassGold,
            background: PTDesignSystem.Color.deepOps,
            text: "BrassGold on DeepOps"
        )
        
        ContrastRatioPreview(
            foreground: PTDesignSystem.Color.tacticalGray,
            background: PTDesignSystem.Color.cream,
            text: "TacticalGray on Cream"
        )
    }
    .padding()
} 