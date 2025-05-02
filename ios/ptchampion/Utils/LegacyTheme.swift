import SwiftUI

// MARK: - Legacy Theme System
// This file is being phased out. 
// New code should use AppTheme from Theme/AppTheme.swift

// Removed conflicting color definitions. Use AppTheme.Colors instead.
// enum LegacyColors { ... } was removed.
// extension Color { ... } defining static color vars was removed.

// We'll keep the hex color helper if it's still needed elsewhere,
// but rename it to LegacyColor to avoid conflicts
public struct LegacyColor {
    // Helper to initialize Color from HEX string (including alpha)
    public static func fromHex(_ hex: String) -> Color {
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
            (a, r, g, b) = (255, 0, 0, 0) // Default to black
        }
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Font Definitions (Legacy - Use AppTheme.Typography)

struct AppFonts {
    // Ensure these fonts are added to the project and Info.plist
    static let heading = "BebasNeue-Bold" // Assuming Bold variant exists
    static let subheading = "Montserrat-SemiBold"
    static let body = "Montserrat-Regular"
    static let bodyBold = "Montserrat-Bold"
    static let mono = "RobotoMono-Medium"
    static let monoBold = "RobotoMono-Bold" // Example if needed
}

// MARK: - Text Style ViewModifiers (Legacy - Use AppTheme styles)

struct HeadingTextStyle: ViewModifier {
    let size: CGFloat
    let color: Color

    // Updated to use AppTheme color, but still legacy modifier
    init(size: CGFloat = 28, color: Color = AppTheme.Colors.commandBlack) { 
        self.size = size
        self.color = color
    }

    func body(content: Content) -> some View {
        content
            .font(.custom(AppFonts.heading, size: size))
            .foregroundColor(color)
            .textCase(.uppercase)
    }
}

struct SubheadingTextStyle: ViewModifier {
    let size: CGFloat
    let color: Color

    // Updated to use AppTheme color, but still legacy modifier
    init(size: CGFloat = 19, color: Color = AppTheme.Colors.tacticalGray) { 
        self.size = size
        self.color = color
    }

    func body(content: Content) -> some View {
        content
            .font(.custom(AppFonts.subheading, size: size))
            .foregroundColor(color)
            .textCase(.uppercase)
    }
}

struct StatsNumberTextStyle: ViewModifier {
    let size: CGFloat
    let color: Color

    // Updated to use AppTheme color, but still legacy modifier
    init(size: CGFloat = 24, color: Color = AppTheme.Colors.commandBlack) { 
        self.size = size
        self.color = color
    }

    func body(content: Content) -> some View {
        content
            .font(.custom(AppFonts.mono, size: size, relativeTo: .title3))
            .foregroundColor(color)
    }
}

struct LabelTextStyle: ViewModifier {
    let size: CGFloat
    let color: Color

    // Updated to use AppTheme color, but still legacy modifier
    init(size: CGFloat = 13, color: Color = AppTheme.Colors.tacticalGray) { 
        self.size = size
        self.color = color
    }

    func body(content: Content) -> some View {
        content
            .font(.custom(AppFonts.body, size: size, relativeTo: .caption))
            .foregroundColor(color)
    }
}

struct ButtonTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.custom(AppFonts.bodyBold, size: 14))
            .foregroundColor(AppTheme.Colors.commandBlack) // Updated
            .textCase(.uppercase)
    }
}

struct NavLabelTextStyle: ViewModifier {
     func body(content: Content) -> some View {
        content
            .font(.custom(AppFonts.bodyBold, size: 10))
            .textCase(.uppercase)
    }
}


// MARK: - Convenience Extensions for View Modifiers (Legacy)

extension View {
    // Updated to use AppTheme colors, but still legacy modifiers
    func headingStyle(size: CGFloat = 28, color: Color = AppTheme.Colors.commandBlack) -> some View {
        self.modifier(HeadingTextStyle(size: size, color: color))
    }

    func subheadingStyle(size: CGFloat = 19, color: Color = AppTheme.Colors.tacticalGray) -> some View {
        self.modifier(SubheadingTextStyle(size: size, color: color))
    }

    func statsNumberStyle(size: CGFloat = 24, color: Color = AppTheme.Colors.commandBlack) -> some View {
        self.modifier(StatsNumberTextStyle(size: size, color: color))
    }

    func labelStyle(size: CGFloat = 13, color: Color = AppTheme.Colors.tacticalGray) -> some View {
        self.modifier(LabelTextStyle(size: size, color: color))
    }

    func buttonTextStyle() -> some View {
        self.modifier(ButtonTextStyle())
    }

    func navLabelStyle() -> some View {
         self.modifier(NavLabelTextStyle())
    }
}


// MARK: - Component Styles (Legacy - Use new Button/Card Styles)

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppTheme.Colors.brassGold) // Updated
            .buttonTextStyle() // Applies font, case, color
            .cornerRadius(Theme.AppConstants.Radius.md) // Uses old Theme struct
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppTheme.Colors.armyTan) // Updated
            .buttonTextStyle() // Applies font, case, color
            .cornerRadius(Theme.AppConstants.Radius.md) // Uses old Theme struct
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.AppConstants.Radius.md) // Uses old Theme struct
                    .stroke(AppTheme.Colors.brassGold, lineWidth: 1) // Updated
            )
            .foregroundColor(AppTheme.Colors.brassGold) // Updated
            .font(.custom(AppFonts.bodyBold, size: 14))
            .textCase(.uppercase)
            .cornerRadius(Theme.AppConstants.Radius.md) // Uses old Theme struct
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.clear)
            .foregroundColor(AppTheme.Colors.brassGold) // Updated
            .font(.custom(AppFonts.bodyBold, size: 14))
            .textCase(.uppercase)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.AppConstants.Spacing.md) // Uses old Theme struct
            .background(AppTheme.Colors.cream) // Updated
            .cornerRadius(Theme.AppConstants.Radius.md) // Uses old Theme struct
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Button Extensions (Legacy)

extension View {
    func primaryButtonStyle() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }
    
    func secondaryButtonStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
    
    func outlineButtonStyle() -> some View {
        self.buttonStyle(OutlineButtonStyle())
    }
    
    func ghostButtonStyle() -> some View {
        self.buttonStyle(GhostButtonStyle())
    }
    
    func cardStyle() -> some View {
        self.modifier(CardBackground())
    }
}

// MARK: - App Constants (Legacy - Use AppTheme constants)
// Keeping the Theme struct for now because button styles reference its constants
// This should be refactored later.
enum Theme {
    enum AppConstants {
        // Enum for distance units
        enum DistanceUnit: String, Codable, CaseIterable {
            case kilometers = "km"
            case miles = "mi"

            var id: String { self.rawValue }

            var displayName: String {
                switch self {
                case .kilometers: return "Kilometers"
                case .miles: return "Miles"
                }
            }

            // Conversion factor from meters
            func convertFromMeters(_ meters: Double) -> Double {
                switch self {
                case .kilometers: return meters / 1000.0
                case .miles: return meters / 1609.34
                }
            }
        }
        
        // Spacing (from design-tokens.json)
        enum Spacing {
            static let xs: CGFloat = 4
            static let sm: CGFloat = 8
            static let md: CGFloat = 16
            static let lg: CGFloat = 24
            static let xl: CGFloat = 32
            static let xxl: CGFloat = 48
            static let xxxl: CGFloat = 64
        }
        
        // Radius (from design-tokens.json)
        enum Radius {
            static let none: CGFloat = 0
            static let sm: CGFloat = 4
            static let md: CGFloat = 8
            static let lg: CGFloat = 12
            static let xl: CGFloat = 16
            static let full: CGFloat = 9999
        }
        
        // Font Size (from design-tokens.json)
        enum FontSize {
            static let xs: CGFloat = 10
            static let sm: CGFloat = 12
            static let md: CGFloat = 14
            static let lg: CGFloat = 16
            static let xl: CGFloat = 20
            static let xxl: CGFloat = 24
            static let xxxl: CGFloat = 30
            static let xxxxl: CGFloat = 36
        }
        
        // Animation Durations
        enum Animation {
            static let standard = SwiftUI.Animation.easeInOut(duration: 0.2)
            static let slow = SwiftUI.Animation.easeInOut(duration: 0.3)
        }
    }
} 