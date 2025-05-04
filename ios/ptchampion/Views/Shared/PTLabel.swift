import SwiftUI
import PTDesignSystem

/// A styled text component with standardized typography using design tokens
struct PTLabel: View {
    enum Style {
        case heading
        case subheading
        case body
        case bodyBold
        case caption
        
        var font: Font {
            switch self {
            case .heading:
                return AppTheme.GeneratedTypography.heading(size: nil)
            case .subheading:
                return AppTheme.GeneratedTypography.subheading(size: nil)
            case .body:
                return AppTheme.GeneratedTypography.body(size: nil)
            case .bodyBold:
                return AppTheme.GeneratedTypography.bodyBold(size: nil)
            case .caption:
                return AppTheme.GeneratedTypography.caption(size: nil)
            }
        }
    }
    
    enum Size {
        case large
        case medium
        case small
        
        func value(for style: Style) -> CGFloat {
            switch (style, self) {
            case (.heading, .large): return AppTheme.GeneratedTypography.heading1
            case (.heading, .medium): return AppTheme.GeneratedTypography.heading2
            case (.heading, .small): return AppTheme.GeneratedTypography.heading3
            case (.subheading, .large): return AppTheme.GeneratedTypography.heading3
            case (.subheading, .medium): return AppTheme.GeneratedTypography.heading4
            case (.subheading, .small): return AppTheme.GeneratedTypography.body
            case (.body, _), (.bodyBold, _): 
                switch self {
                case .large: return AppTheme.GeneratedTypography.body + 2
                case .medium: return AppTheme.GeneratedTypography.body
                case .small: return AppTheme.GeneratedTypography.small
                }
            case (.caption, _):
                switch self {
                case .large: return AppTheme.GeneratedTypography.small
                case .medium, .small: return AppTheme.GeneratedTypography.tiny
                }
            }
        }
    }
    
    private let text: String
    private let style: Style
    private let size: Size
    
    init(_ text: String, style: Style = .body, size: Size = .medium) {
        self.text = text
        self.style = style
        self.size = size
    }
    
    var body: some View {
        Text(text)
            .font(style.font.size(size.value(for: style)))
    }
}

// Preview
struct PTLabel_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                PTLabel("Heading Large", style: .heading, size: .large)
                PTLabel("Heading Medium", style: .heading, size: .medium)
                PTLabel("Heading Small", style: .heading, size: .small)
            }
            
            Divider()
            
            Group {
                PTLabel("Subheading Large", style: .subheading, size: .large)
                PTLabel("Subheading Medium", style: .subheading, size: .medium)
                PTLabel("Subheading Small", style: .subheading, size: .small)
            }
            
            Divider()
            
            Group {
                PTLabel("Body Large", style: .body, size: .large)
                PTLabel("Body Medium", style: .body) // Default is medium
                PTLabel("Body Small", style: .body, size: .small)
                
                PTLabel("Body Bold Large", style: .bodyBold, size: .large)
                PTLabel("Body Bold Medium", style: .bodyBold)
                PTLabel("Body Bold Small", style: .bodyBold, size: .small)
            }
            
            Divider()
            
            Group {
                PTLabel("Caption Large", style: .caption, size: .large)
                PTLabel("Caption Medium", style: .caption)
                PTLabel("Caption Small", style: .caption, size: .small)
            }
        }
        .padding()
    }
} 