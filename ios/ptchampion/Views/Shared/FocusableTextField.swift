import SwiftUI
import PTDesignSystem
import SwiftUIIntrospect
/// A text field that shows a focus ring when focused using keyboard or accessibility
///
/// This component provides a focus state that changes the appearance when the field is selected.
/// While PTTextField is the recommended text field component for most cases, FocusableTextField
/// can be used when specific focus ring behavior is needed.
///
/// TODO: Consider integrating this focus behavior into PTTextField in the future to
/// standardize on a single text field implementation across the app.
public struct FocusableTextField: View {
    @Binding private var text: String
    private let placeholder: String
    private let label: String?
    private let isSecure: Bool
    private let keyboardType: UIKeyboardType
    private let icon: Image?
    
    @FocusState private var isFocused: Bool
    
    public init(
        _ placeholder: String,
        text: Binding<String>,
        label: String? = nil,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        icon: Image? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.label = label
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.icon = icon
    }
    
    public var body: some View {
        PTTextField(
            placeholder,
            text: $text,
            label: label,
            isSecure: isSecure,
            icon: icon,
            keyboardType: keyboardType
        )
        .focused($isFocused)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.input)
                .stroke(isFocused ? AppTheme.GeneratedColors.brassGold : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .introspect(.textField) { (textField: UITextField) in
            // Disable password suggestions
            if isSecure {
                textField.textContentType = nil
                textField.passwordRules = nil
                
                #if targetEnvironment(simulator)
                // This addresses the automatic strong password suggestion in simulator
                textField.isSecureTextEntry = true
                textField.textContentType = UITextContentType.oneTimeCode // This prevents auto-fill on simulator
                #endif
            }
        }
    }
}

/// Custom text field style that visually indicates focus state
/// 
/// Highlights the text field border with the accent color when focused
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

// Add focus capability to PTTextField
extension PTTextField {
    /// Adds a focus ring to a PTTextField when it becomes focused
    /// 
    /// This is a convenience extension that adds a gold focus ring to any PTTextField
    /// when it receives keyboard focus.
    public func withFocusRing(_ isFocused: FocusState<Bool>.Binding) -> some View {
        self
            .focused(isFocused)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.input)
                    .stroke(isFocused.wrappedValue ? AppTheme.GeneratedColors.brassGold : Color.clear, lineWidth: 2)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused.wrappedValue)
    }
}

struct FocusableTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            FocusableTextField(
                "Enter your name",
                text: .constant("")
            )
            
            FocusableTextField(
                "Email",
                text: .constant("user@example.com"),
                keyboardType: .emailAddress,
                icon: Image(systemName: "envelope")
            )
            
            FocusableTextField(
                "Password",
                text: .constant("password123"),
                isSecure: true,
                icon: Image(systemName: "lock")
            )
            
            // Example of using the extension method
            @FocusState var isFieldFocused: Bool
            
            PTTextField("Using extension", text: .constant("Extension example"))
                .withFocusRing($isFieldFocused)
        }
        .padding()
        .background(AppTheme.GeneratedColors.background)
        .previewLayout(.sizeThatFits)
    }
} 