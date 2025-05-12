import SwiftUI

/// Container styling constants - aligned with web spacing system
struct ContainerStyle {
    // Matches the web spacing variables in tailwind.config.js
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let section: CGFloat = 32
        static let cardGap: CGFloat = 16
        static let contentPadding: CGFloat = 16
        static let item: CGFloat = 12
    }
    
    // Container properties
    static let horizontalPadding: CGFloat = Spacing.contentPadding
    static let verticalPadding: CGFloat = Spacing.md
    static let maxWidth: CGFloat = 1024 // matches web max-width from tailwind config
    
    // Device-specific paddings
    static var responsiveHorizontalPadding: CGFloat {
        // For iPad or large devices
        if UIDevice.current.userInterfaceIdiom == .pad {
            return Spacing.section
        } else {
            return horizontalPadding
        }
    }
    
    // Section properties
    static let sectionSpacing: CGFloat = Spacing.section
    static let sectionTitleBottomMargin: CGFloat = Spacing.md
    
    // Radius values (matching web)
    struct Radius {
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let card: CGFloat = 16
        static let panel: CGFloat = 12
        static let button: CGFloat = 8
        static let input: CGFloat = 8
        static let badge: CGFloat = 9999 // "full" in tailwind
    }
}

/// A ViewModifier for applying standard container styling
struct ContainerModifier: ViewModifier {
    let horizontalPadding: CGFloat
    let useMaxWidth: Bool
    
    init(horizontalPadding: CGFloat? = nil, useMaxWidth: Bool = true) {
        self.horizontalPadding = horizontalPadding ?? ContainerStyle.responsiveHorizontalPadding
        self.useMaxWidth = useMaxWidth
    }
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontalPadding)
            .if(useMaxWidth) { view in
                view.frame(maxWidth: ContainerStyle.maxWidth, alignment: .center)
            }
    }
}

/// A ViewModifier for applying section styling
struct SectionModifier: ViewModifier {
    let spacing: CGFloat
    
    init(spacing: CGFloat? = nil) {
        self.spacing = spacing ?? ContainerStyle.sectionSpacing
    }
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, spacing)
    }
}

// Extensions for applying modifiers
extension View {
    /// Apply standard container styling
    func container(horizontalPadding: CGFloat? = nil, useMaxWidth: Bool = true) -> some View {
        modifier(ContainerModifier(horizontalPadding: horizontalPadding, useMaxWidth: useMaxWidth))
    }
    
    /// Apply section styling
    func section(spacing: CGFloat? = nil) -> some View {
        modifier(SectionModifier(spacing: spacing))
    }
    
    /// Apply padding based on container spacing
    func contentPadding() -> some View {
        padding(ContainerStyle.Spacing.contentPadding)
    }
    
    /// Apply horizontal padding
    func horizontalPadding() -> some View {
        padding(.horizontal, ContainerStyle.horizontalPadding)
    }
}

// For layout grids
struct ResponsiveGridLayout {
    static func columns(minWidth: CGFloat = 280, spacing: CGFloat = ContainerStyle.Spacing.cardGap) -> [GridItem] {
        [GridItem(.adaptive(minimum: minWidth), spacing: spacing)]
    }
} 