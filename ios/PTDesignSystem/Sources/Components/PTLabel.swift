import SwiftUI
import DesignTokens

public struct PTLabel: View {
    private let text: String
    private let style: LabelStyle
    
    public enum LabelStyle {
        case heading, subheading, body, bodyBold, caption
    }
    
    public init(_ text: String, style: LabelStyle = .body) {
        self.text = text
        self.style = style
    }
    
    public var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
    }
    
    private var font: Font {
        switch style {
        case .heading:
            return .system(size: 24, weight: .bold)
        case .subheading:
            return .system(size: 20, weight: .semibold)
        case .body:
            return .system(size: 16, weight: .regular)
        case .bodyBold:
            return .system(size: 16, weight: .bold)
        case .caption:
            return .system(size: 14, weight: .regular)
        }
    }
    
    private var color: Color {
        switch style {
        case .heading, .subheading:
            return AppTheme.GeneratedColors.textPrimary
        case .body, .bodyBold:
            return AppTheme.GeneratedColors.textSecondary
        case .caption:
            return AppTheme.GeneratedColors.textTertiary
        }
    }
}

// MARK: – Temporarily keep the "size:" API alive for the Gallery

public extension PTLabel {

    enum LabelSize { case small, medium, large }

    /// Drop-in replacement for the old init(…, size:) that now returns `some View`.
    static func sized(_ text: String,
                      style: LabelStyle = .body,
                      size: LabelSize) -> some View {

        let base = PTLabel(text, style: style)

        let customFont: Font
        switch (style, size) {
        case (.heading,    .large):  customFont = .system(size: 28, weight: .bold)
        case (.heading,    .medium): customFont = .system(size: 24, weight: .bold)
        case (.heading,    .small):  customFont = .system(size: 20, weight: .bold)

        case (.subheading, .large):  customFont = .system(size: 22, weight: .semibold)
        case (.subheading, .medium): customFont = .system(size: 18, weight: .semibold)
        case (.subheading, .small):  customFont = .system(size: 16, weight: .semibold)

        case (.body,       .large):  customFont = .system(size: 18)
        case (.body,       .medium): customFont = .system(size: 16)
        case (.body,       .small):  customFont = .system(size: 14)
            
        case (.bodyBold,   .large):  customFont = .system(size: 18, weight: .bold)
        case (.bodyBold,   .medium): customFont = .system(size: 16, weight: .bold)
        case (.bodyBold,   .small):  customFont = .system(size: 14, weight: .bold)

        case (.caption,    .large):  customFont = .system(size: 16)
        case (.caption,    .medium): customFont = .system(size: 14)
        case (.caption,    .small):  customFont = .system(size: 12)
        }

        return base.font(customFont)
    }
}

public struct PTLabel_Previews: PreviewProvider {
    public static var previews: some View {
        VStack(alignment: .leading, spacing: 16) {
            PTLabel("Heading Text", style: .heading)
            PTLabel("Subheading Text", style: .subheading)
            PTLabel("Body Text", style: .body)
            PTLabel("Body Bold Text", style: .bodyBold)
            PTLabel("Caption Text", style: .caption)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
