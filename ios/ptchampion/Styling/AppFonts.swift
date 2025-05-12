import SwiftUI

struct AppFonts {
    // MARK: - Font Names
    
    // These are the canonical font family and style names
    private enum FontName {
        // Primary font (Helvetica Neue)
        static let regular = "HelveticaNeue"
        static let medium = "HelveticaNeue-Medium"
        static let semibold = "HelveticaNeue-Semibold"
        static let bold = "HelveticaNeue-Bold"
        
        // Monospaced font (matching web: Consolas, Monaco, Courier New)
        static let mono = "Menlo-Regular"
        static let monoBold = "Menlo-Bold"
    }
    
    // MARK: - Font Sizes (matching web typography)
    
    struct FontSize {
        static let heading1: CGFloat = 32
        static let heading2: CGFloat = 24
        static let heading3: CGFloat = 20
        static let heading4: CGFloat = 18
        static let body: CGFloat = 16
        static let small: CGFloat = 14
        static let tiny: CGFloat = 12
    }
    
    // MARK: - Font Providers
    
    // Regular text styles
    static func regular(size: CGFloat, relativeTo: Font.TextStyle? = nil) -> Font {
        if let textStyle = relativeTo {
            return Font.custom(FontName.regular, size: size, relativeTo: textStyle)
        }
        return Font.custom(FontName.regular, size: size)
    }
    
    static func medium(size: CGFloat, relativeTo: Font.TextStyle? = nil) -> Font {
        if let textStyle = relativeTo {
            return Font.custom(FontName.medium, size: size, relativeTo: textStyle)
        }
        return Font.custom(FontName.medium, size: size)
    }
    
    static func semibold(size: CGFloat, relativeTo: Font.TextStyle? = nil) -> Font {
        if let textStyle = relativeTo {
            return Font.custom(FontName.semibold, size: size, relativeTo: textStyle)
        }
        return Font.custom(FontName.semibold, size: size)
    }
    
    static func bold(size: CGFloat, relativeTo: Font.TextStyle? = nil) -> Font {
        if let textStyle = relativeTo {
            return Font.custom(FontName.bold, size: size, relativeTo: textStyle)
        }
        return Font.custom(FontName.bold, size: size)
    }
    
    // Monospaced styles
    static func mono(size: CGFloat, relativeTo: Font.TextStyle? = nil) -> Font {
        if let textStyle = relativeTo {
            return Font.custom(FontName.mono, size: size, relativeTo: textStyle)
        }
        return Font.custom(FontName.mono, size: size)
    }
    
    static func monoBold(size: CGFloat, relativeTo: Font.TextStyle? = nil) -> Font {
        if let textStyle = relativeTo {
            return Font.custom(FontName.monoBold, size: size, relativeTo: textStyle)
        }
        return Font.custom(FontName.monoBold, size: size)
    }
    
    // MARK: - Typography Styles
    
    struct TextStyle {
        var font: Font
        var tracking: CGFloat
        var lineSpacing: CGFloat
        
        init(font: Font, tracking: CGFloat = 0, lineSpacing: CGFloat = 4) {
            self.font = font
            self.tracking = tracking
            self.lineSpacing = lineSpacing
        }
    }
    
    // Heading styles
    static let heading1 = TextStyle(
        font: bold(size: FontSize.heading1, relativeTo: .largeTitle),
        tracking: 0.5,
        lineSpacing: 8
    )
    
    static let heading2 = TextStyle(
        font: bold(size: FontSize.heading2, relativeTo: .title),
        tracking: 0.5,
        lineSpacing: 6
    )
    
    static let heading3 = TextStyle(
        font: bold(size: FontSize.heading3, relativeTo: .title2),
        tracking: 0.5
    )
    
    static let heading4 = TextStyle(
        font: bold(size: FontSize.heading4, relativeTo: .title3),
        tracking: 0.25
    )
    
    // Body styles
    static let body = TextStyle(
        font: regular(size: FontSize.body, relativeTo: .body)
    )
    
    static let bodyBold = TextStyle(
        font: bold(size: FontSize.body, relativeTo: .body)
    )
    
    static let bodySemibold = TextStyle(
        font: semibold(size: FontSize.body, relativeTo: .body)
    )
    
    // Small styles
    static let small = TextStyle(
        font: regular(size: FontSize.small, relativeTo: .subheadline),
        lineSpacing: 2
    )
    
    static let smallSemibold = TextStyle(
        font: semibold(size: FontSize.small, relativeTo: .subheadline),
        lineSpacing: 2
    )
    
    // Special styles
    static let caption = TextStyle(
        font: regular(size: FontSize.tiny, relativeTo: .caption),
        lineSpacing: 1
    )
    
    static let label = TextStyle(
        font: semibold(size: FontSize.small, relativeTo: .subheadline),
        tracking: 1.25,
        lineSpacing: 0
    )
    
    static let metric = TextStyle(
        font: mono(size: FontSize.heading3, relativeTo: .title2)
    )
    
    static let code = TextStyle(
        font: mono(size: FontSize.body, relativeTo: .body)
    )
} 