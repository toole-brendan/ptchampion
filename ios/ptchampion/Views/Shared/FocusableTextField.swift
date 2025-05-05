import SwiftUI
import PTDesignSystem
/// A text field that shows a focus ring when focused using keyboard or accessibility
public struct FocusableTextField: View {
    @Binding private var text: String
    private let placeholder: String
    private let isSecure: Bool
    private let keyboardType: UIKeyboardType
    
    @FocusState private var isFocused: Bool
    
    public init(
        text: Binding<String>,
        placeholder: String,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default
    ) {
        self._text = text
        self.placeholder = placeholder
        self.isSecure = isSecure
        self.keyboardType = keyboardType
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .focused($isFocused)
                    .textFieldStyle(FocusableTextFieldStyle(isFocused: isFocused))
                    .keyboardType(keyboardType)
            } else {
                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .textFieldStyle(FocusableTextFieldStyle(isFocused: isFocused))
                    .keyboardType(keyboardType)
            }
        }
    }
}

struct FocusableTextFieldStyle: TextFieldStyle {
    let isFocused: Bool
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppTheme.GeneratedColors.cardBackground)
            .cornerRadius(AppTheme.GeneratedRadius.input)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.input)
                    .stroke(isFocused ? AppTheme.GeneratedColors.brassGold : Color.gray.opacity(0.3), lineWidth: isFocused ? 2 : 1)
            )
            .font(AppTheme.GeneratedTypography.body())
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isFocused)
    }
}

struct FocusableTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            FocusableTextField(
                text: .constant(""),
                placeholder: "Enter your name"
            )
            
            FocusableTextField(
                text: .constant("user@example.com"),
                placeholder: "Email",
                keyboardType: .emailAddress
            )
            
            FocusableTextField(
                text: .constant("password"),
                placeholder: "Password",
                isSecure: true
            )
        }
        .padding()
        .background(AppTheme.GeneratedColors.background)
        .previewLayout(.sizeThatFits)
    }
} 