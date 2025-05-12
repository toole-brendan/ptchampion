import SwiftUI

/// A ViewModifier that applies a TextStyle to a Text view
struct TypographyModifier: ViewModifier {
    let style: AppFonts.TextStyle
    let color: Color?
    
    init(style: AppFonts.TextStyle, color: Color? = nil) {
        self.style = style
        self.color = color
    }
    
    func body(content: Content) -> some View {
        content
            .font(style.font)
            .tracking(style.tracking)
            .lineSpacing(style.lineSpacing)
            .if(color != nil) { view in
                view.foregroundColor(color)
            }
    }
}

// Extension to provide a conditional modifier
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// Extension to make applying typography styles easy
extension View {
    func typography(_ style: AppFonts.TextStyle, color: Color? = nil) -> some View {
        modifier(TypographyModifier(style: style, color: color))
    }
}

// Extension specifically for Text views
extension Text {
    func heading1(color: Color? = .foreground) -> some View {
        self.modifier(TypographyModifier(style: AppFonts.heading1, color: color))
    }
    
    func heading2(color: Color? = .foreground) -> some View {
        self.modifier(TypographyModifier(style: AppFonts.heading2, color: color))
    }
    
    func heading3(color: Color? = .foreground) -> some View {
        self.modifier(TypographyModifier(style: AppFonts.heading3, color: color))
    }
    
    func heading4(color: Color? = .foreground) -> some View {
        self.modifier(TypographyModifier(style: AppFonts.heading4, color: color))
    }
    
    func body(color: Color? = .foreground) -> some View {
        self.modifier(TypographyModifier(style: AppFonts.body, color: color))
    }
    
    func bodyBold(color: Color? = .foreground) -> some View {
        self.modifier(TypographyModifier(style: AppFonts.bodyBold, color: color))
    }
    
    func bodySemibold(color: Color? = .foreground) -> some View {
        self.modifier(TypographyModifier(style: AppFonts.bodySemibold, color: color))
    }
    
    func small(color: Color? = .foreground) -> some View {
        self.modifier(TypographyModifier(style: AppFonts.small, color: color))
    }
    
    func smallSemibold(color: Color? = .foreground) -> some View {
        self.modifier(TypographyModifier(style: AppFonts.smallSemibold, color: color))
    }
    
    func caption(color: Color? = .mutedForeground) -> some View {
        self.modifier(TypographyModifier(style: AppFonts.caption, color: color))
    }
    
    func label(color: Color? = .tacticalGray) -> some View {
        self.modifier(TypographyModifier(style: AppFonts.label, color: color))
    }
    
    func metric(color: Color? = .foreground) -> some View {
        self.modifier(TypographyModifier(style: AppFonts.metric, color: color))
    }
    
    func code(color: Color? = .foreground) -> some View {
        self.modifier(TypographyModifier(style: AppFonts.code, color: color))
    }
} 