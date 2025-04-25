import SwiftUI

// MARK: - Color Palette

extension Color {
    // Auto-generated from design-tokens.json for consistency with web
    static let tacticalCream = Color(hex: "#F4F1E6")
    static let deepOpsGreen = Color(hex: "#1E241E")
    static let brassGold = Color(hex: "#BFA24D")
    static let armyTan = Color(hex: "#E0D4A6") 
    static let oliveMist = Color(hex: "#C9CCA6") 
    static let commandBlack = Color(hex: "#1E1E1E")
    static let tacticalGray = Color(hex: "#4E5A48")
    static let gridlineGray = Color(hex: "#E3E0D5") 
    static let inactiveGray = Color(hex: "#A3A390")
    
    // Additional semantic colors not from design-tokens.json
    static let tomahawkRed = Color(hex: "#DC2626") // For errors, warnings
    static let successGreen = Color(hex: "#10B981") // For success states
    
    // Helper to initialize Color from HEX string (including alpha)
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
            (a, r, g, b) = (255, 0, 0, 0) // Default to black
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

// MARK: - Font Definitions

struct AppFonts {
    // Ensure these fonts are added to the project and Info.plist
    static let heading = "BebasNeue-Bold" // Assuming Bold variant exists
    static let subheading = "Montserrat-SemiBold"
    static let body = "Montserrat-Regular"
    static let bodyBold = "Montserrat-Bold"
    static let mono = "RobotoMono-Medium"
    static let monoBold = "RobotoMono-Bold" // Example if needed
}

// MARK: - Text Style ViewModifiers

struct HeadingTextStyle: ViewModifier {
    let size: CGFloat
    let color: Color

    init(size: CGFloat = 28, color: Color = .commandBlack) {
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

    init(size: CGFloat = 19, color: Color = .tacticalGray) {
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

    init(size: CGFloat = 24, color: Color = .commandBlack) {
        self.size = size
        self.color = color
    }

    func body(content: Content) -> some View {
        content
            .font(.custom(AppFonts.mono, size: size, relativeTo: .title3)) // Relative sizing is good practice
            .foregroundColor(color)
    }
}

struct LabelTextStyle: ViewModifier {
    let size: CGFloat
    let color: Color

    init(size: CGFloat = 13, color: Color = .tacticalGray) {
        self.size = size
        self.color = color
    }

    func body(content: Content) -> some View {
        content
            .font(.custom(AppFonts.body, size: size, relativeTo: .caption))
            .foregroundColor(color)
            // Style guide says Sentence case, so no .textCase modifier
    }
}

struct ButtonTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.custom(AppFonts.bodyBold, size: 14))
            .foregroundColor(.commandBlack)
            .textCase(.uppercase)
    }
}

struct NavLabelTextStyle: ViewModifier {
     func body(content: Content) -> some View {
        content
            .font(.custom(AppFonts.bodyBold, size: 10)) // Style guide says Montserrat UPPERCASE 10px
            .textCase(.uppercase)
            // Color is set by TabView item selection state
    }
}


// MARK: - Convenience Extensions for View Modifiers

extension View {
    func headingStyle(size: CGFloat = 28, color: Color = .commandBlack) -> some View {
        self.modifier(HeadingTextStyle(size: size, color: color))
    }

    func subheadingStyle(size: CGFloat = 19, color: Color = .tacticalGray) -> some View {
        self.modifier(SubheadingTextStyle(size: size, color: color))
    }

    func statsNumberStyle(size: CGFloat = 24, color: Color = .commandBlack) -> some View {
        self.modifier(StatsNumberTextStyle(size: size, color: color))
    }

    func labelStyle(size: CGFloat = 13, color: Color = .tacticalGray) -> some View {
        self.modifier(LabelTextStyle(size: size, color: color))
    }

    func buttonTextStyle() -> some View {
        self.modifier(ButtonTextStyle())
    }

    func navLabelStyle() -> some View {
         self.modifier(NavLabelTextStyle())
    }
}


// MARK: - Component Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.brassGold)
            .buttonTextStyle() // Applies font, case, color
            .cornerRadius(AppConstants.Radius.md)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.armyTan)
            .buttonTextStyle() // Applies font, case, color
            .cornerRadius(AppConstants.Radius.md)
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
                RoundedRectangle(cornerRadius: AppConstants.Radius.md)
                    .stroke(Color.brassGold, lineWidth: 1)
            )
            .foregroundColor(.brassGold)
            .font(.custom(AppFonts.bodyBold, size: 14))
            .textCase(.uppercase)
            .cornerRadius(AppConstants.Radius.md)
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
            .foregroundColor(.brassGold)
            .font(.custom(AppFonts.bodyBold, size: 14))
            .textCase(.uppercase)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppConstants.Spacing.md) // Use the AppConstants.Spacing
            .background(Color.tacticalCream)
            .cornerRadius(AppConstants.Radius.md)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1) // Soft shadow
    }
}

// MARK: - Button Extensions

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

// MARK: - App Constants (Single source of truth for spacing/sizing)
// This replaces the duplicated AppConstants defined elsewhere

struct AppConstants {
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

// Note: Font files (BebasNeue, Montserrat, RobotoMono) need to be added to the
// Xcode project, included in the target, and declared in Info.plist under
// "Fonts provided by application". 