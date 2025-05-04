import SwiftUI
import DesignTokens

public struct PTTextField: View {
    private let placeholder: String
    private let isSecure: Bool
    @Binding private var text: String
    
    public init(_ placeholder: String, text: Binding<String>, isSecure: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !text.isEmpty {
                Text(placeholder)
                    .font(.caption)
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
            }
            
            Group {
                if isSecure {
                    SecureField(text.isEmpty ? placeholder : "", text: $text)
                } else {
                    TextField(text.isEmpty ? placeholder : "", text: $text)
                }
            }
            .padding(12)
            .background(AppTheme.GeneratedColors.background)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.GeneratedColors.textSecondary.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct PTTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PTTextField("Email", text: .constant(""))
            PTTextField("Email", text: .constant("user@example.com"))
            PTTextField("Password", text: .constant(""), isSecure: true)
        }
        .padding()
        .preferredColorScheme(.light)
        
        VStack(spacing: 20) {
            PTTextField("Email", text: .constant(""))
            PTTextField("Email", text: .constant("user@example.com"))
            PTTextField("Password", text: .constant(""), isSecure: true)
        }
        .padding()
        .preferredColorScheme(.dark)
    }
} 