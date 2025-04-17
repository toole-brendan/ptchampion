import SwiftUI

// MARK: - Color Palette

extension Color {
    static let tacticalCream = Color(hex: "#F4F1E6")
    static let deepOpsGreen = Color(hex: "#1E241E")
    static let brassGold = Color(hex: "#BFA24D")
    static let armyTan = Color(hex: "#E0D4A6") // Optional highlight
    static let oliveMist = Color(hex: "#C9CCA6") // Chart fill base
    static let commandBlack = Color(hex: "#1E1E1E")
    static let tacticalGray = Color(hex: "#4E5A48")
    static let gridlineGray = Color(hex: "#E3E0D5") // Chart gridlines
    static let inactiveGray = Color(hex: "#A3A390") // Inactive nav icons

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
    let size: CGFloat = 28 // Default, adjust as needed per specific usage
    let color: Color = .commandBlack

    func body(content: Content) -> some View {
        content
            .font(.custom(AppFonts.heading, size: size))
            .foregroundColor(color)
            .textCase(.uppercase)
    }
}

struct SubheadingTextStyle: ViewModifier {
    let size: CGFloat = 19 // Default
    let color: Color = .tacticalGray

    func body(content: Content) -> some View {
        content
            .font(.custom(AppFonts.subheading, size: size))
            .foregroundColor(color)
            .textCase(.uppercase)
    }
}

struct StatsNumberTextStyle: ViewModifier {
    let size: CGFloat = 24 // Default
    let color: Color = .commandBlack // Or .brassGold for highlights

    func body(content: Content) -> some View {
        content
            .font(.custom(AppFonts.mono, size: size, relativeTo: .title3)) // Relative sizing is good practice
            .foregroundColor(color)
    }
}

struct LabelTextStyle: ViewModifier {
    let size: CGFloat = 13 // Default
    let color: Color = .tacticalGray

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


// MARK: - Component Styles (Examples)

struct AppConstants {
    static let cardCornerRadius: CGFloat = 12
    static let panelCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 8
    static let globalPadding: CGFloat = 20
    static let cardGap: CGFloat = 12
    static let bottomNavHeight: CGFloat = 60 // Reference, actual height determined by TabView
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.brassGold)
            .buttonTextStyle() // Applies font, case, color
            .cornerRadius(AppConstants.buttonCornerRadius)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppConstants.globalPadding / 1.5) // Slightly less padding inside card
            .background(Color.tacticalCream)
            .cornerRadius(AppConstants.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1) // Soft shadow
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardBackground())
    }
}

// Note: Font files (BebasNeue, Montserrat, RobotoMono) need to be added to the
// Xcode project, included in the target, and declared in Info.plist under
// "Fonts provided by application". 