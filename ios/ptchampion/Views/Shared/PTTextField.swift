import SwiftUI
import PTDesignSystem

struct PTTextField: View {
    enum ValidationState {
        case none
        case valid
        case invalid(message: String)
        
        var icon: String? {
            switch self {
            case .valid: return "checkmark.circle.fill"
            case .invalid: return "exclamationmark.circle.fill"
            default: return nil
            }
        }
        
        var iconColor: Color {
            switch self {
            case .valid: return AppTheme.GeneratedColors.success // success green
            case .invalid: return AppTheme.GeneratedColors.error // error red
            default: return .clear
            }
        }
    }
    
    @Binding var text: String
    let label: String
    let placeholder: String
    let icon: Image?
    let validationState: ValidationState
    let isSecure: Bool
    
    // Optional properties with default values
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .none
    var autocorrection: Bool = false
    
    @State private var isEditing: Bool = false
    @State private var secureTextVisible: Bool = false
    
    init(
        text: Binding<String>,
        label: String,
        placeholder: String = "",
        icon: Image? = nil,
        validationState: ValidationState = .none,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .none,
        autocorrection: Bool = false
    ) {
        self._text = text
        self.label = label
        self.placeholder = placeholder
        self.icon = icon
        self.validationState = validationState
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.autocapitalization = autocapitalization
        self.autocorrection = autocorrection
    }
    
    private var shouldShowFloatingLabel: Bool {
        isEditing || !text.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .leading) {
                // Floating label
                Text(label)
                    .font(AppTheme.GeneratedTypography.body(size: shouldShowFloatingLabel ? AppTheme.GeneratedTypography.tiny : AppTheme.GeneratedTypography.body))
                    .foregroundColor(shouldShowFloatingLabel ? AppTheme.GeneratedColors.tacticalGray : AppTheme.GeneratedColors.tacticalGray.opacity(0.7))
                    .offset(y: shouldShowFloatingLabel ? -25 : 0)
                    .animation(.spring(response: 0.2), value: shouldShowFloatingLabel)
                
                HStack(spacing: AppTheme.GeneratedSpacing.small) {
                    // Leading icon if provided
                    if let icon = icon {
                        icon
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                            .foregroundColor(AppTheme.GeneratedColors.tacticalGray)
                    }
                    
                    // Text field or secure field
                    if isSecure && !secureTextVisible {
                        SecureField("", text: $text)
                            .font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.body))
                            .foregroundColor(AppTheme.GeneratedColors.commandBlack)
                            .keyboardType(keyboardType)
                            .textInputAutocapitalization(autocapitalization)
                            .autocorrectionDisabled(!autocorrection)
                            .padding(.top, shouldShowFloatingLabel ? 8 : 0)
                    } else {
                        TextField("", text: $text)
                            .font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.body))
                            .foregroundColor(AppTheme.GeneratedColors.commandBlack)
                            .keyboardType(keyboardType)
                            .textInputAutocapitalization(autocapitalization)
                            .autocorrectionDisabled(!autocorrection)
                            .padding(.top, shouldShowFloatingLabel ? 8 : 0)
                    }
                    
                    // Trailing validation icon or password visibility toggle
                    if isSecure {
                        Button(action: { secureTextVisible.toggle() }) {
                            Image(systemName: secureTextVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(AppTheme.GeneratedColors.tacticalGray)
                                .frame(width: 20, height: 20)
                        }
                    } else if let icon = validationState.icon {
                        Image(systemName: icon)
                            .foregroundColor(validationState.iconColor)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .padding(.vertical, AppTheme.GeneratedSpacing.small)
            .padding(.horizontal, AppTheme.GeneratedSpacing.medium)
            .background(Color.white)
            .cornerRadius(AppTheme.GeneratedRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.medium)
                    .stroke(borderColor, lineWidth: 1)
            )
            .onTapGesture {
                if !isEditing {
                    isEditing = true
                }
            }
            .onSubmit {
                isEditing = false
            }
            
            // Error message
            if case .invalid(let message) = validationState {
                Text(message)
                    .font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.tiny))
                    .foregroundColor(AppTheme.GeneratedColors.error)
                    .padding(.horizontal, AppTheme.GeneratedSpacing.extraSmall)
                    .padding(.top, 2)
            }
        }
    }
    
    // Border color based on state
    private var borderColor: Color {
        if isEditing {
            return AppTheme.GeneratedColors.brassGold
        }
        
        switch validationState {
        case .valid:
            return AppTheme.GeneratedColors.success.opacity(0.5)
        case .invalid:
            return AppTheme.GeneratedColors.error.opacity(0.5)
        case .none:
            return AppTheme.GeneratedColors.cream
        }
    }
}

// MARK: - Preview Provider
struct PTTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AppTheme.GeneratedSpacing.large) {
            // Empty state
            PTTextField(
                text: .constant(""),
                label: "Username",
                placeholder: "Enter username"
            )
            
            // Filled state
            PTTextField(
                text: .constant("johndoe"),
                label: "Username",
                placeholder: "Enter username",
                icon: Image(systemName: "person"),
                validationState: .valid
            )
            
            // Error state
            PTTextField(
                text: .constant("j"),
                label: "Username",
                placeholder: "Enter username",
                validationState: .invalid(message: "Username must be at least 3 characters")
            )
            
            // Password field (secure)
            PTTextField(
                text: .constant("password123"),
                label: "Password",
                placeholder: "Enter password",
                icon: Image(systemName: "lock"),
                isSecure: true
            )
            
            // Email with keyboard type
            PTTextField(
                text: .constant("user@example.com"),
                label: "Email Address",
                placeholder: "Enter email",
                icon: Image(systemName: "envelope"),
                keyboardType: .emailAddress
            )
        }
        .padding()
        .background(AppTheme.GeneratedColors.cream.opacity(0.5))
        .previewLayout(.sizeThatFits)
    }
}

private extension ValidationState {
    var color: Color {
        switch self {
        case .neutral: return AppTheme.GeneratedColors.tacticalGray
        case .valid: return AppTheme.GeneratedColors.success
        case .invalid: return AppTheme.GeneratedColors.error
        }
    }
}

private extension ValidationType {
    var color: Color {
        switch self {
        case .email:
            return AppTheme.GeneratedColors.success.opacity(0.5)
        case .password:
            return AppTheme.GeneratedColors.error.opacity(0.5)
        }
    }
} 