import SwiftUI
import DesignTokens

public struct PTLabel: View {
    private let text: String
    private let style: LabelStyle
    
    public enum LabelStyle {
        case heading, subheading, body, caption
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
        case .caption:
            return .system(size: 14, weight: .regular)
        }
    }
    
    private var color: Color {
        switch style {
        case .heading, .subheading:
            return AppTheme.GeneratedColors.textPrimary
        case .body:
            return AppTheme.GeneratedColors.textSecondary
        case .caption:
            return AppTheme.GeneratedColors.textTertiary
        }
    }
}

struct PTLabel_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 16) {
            PTLabel("Heading Text", style: .heading)
            PTLabel("Subheading Text", style: .subheading)
            PTLabel("Body Text", style: .body)
            PTLabel("Caption Text", style: .caption)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 