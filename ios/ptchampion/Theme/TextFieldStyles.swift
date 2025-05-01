import SwiftUI

struct PTTextFieldStyle: ViewModifier {
    @Binding var isError: Bool
    var isDisabled: Bool = false
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .font(AppTheme.Typography.body())
            .background(isDisabled ? AppTheme.Colors.tacticalGray.opacity(0.1) : AppTheme.Colors.cream)
            .foregroundColor(isDisabled ? AppTheme.Colors.tacticalGray : AppTheme.Colors.textPrimary)
            .cornerRadius(AppTheme.Radius.input)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.input)
                    .stroke(
                        isError ? AppTheme.Colors.error : 
                                  AppTheme.Colors.armyTan.opacity(0.5),
                        lineWidth: 1
                    )
            )
            .disabled(isDisabled)
    }
}

struct TextFieldLabel: View {
    let title: String
    var isRequired: Bool = false
    var isError: Bool = false
    var errorMessage: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.bodySemiBold())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if isRequired {
                    Text("*")
                        .font(AppTheme.Typography.bodySemiBold())
                        .foregroundColor(AppTheme.Colors.error)
                }
            }
            
            if isError && errorMessage != nil {
                Text(errorMessage!)
                    .font(AppTheme.Typography.body(size: 12))
                    .foregroundColor(AppTheme.Colors.error)
            }
        }
    }
}

extension View {
    func ptTextFieldStyle(isError: Binding<Bool> = .constant(false), isDisabled: Bool = false) -> some View {
        self.modifier(PTTextFieldStyle(isError: isError, isDisabled: isDisabled))
    }
}

struct PTTextField: View {
    var title: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    var isRequired: Bool = false
    var isDisabled: Bool = false
    var isError: Bool = false
    var errorMessage: String? = nil
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .sentences
    
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextFieldLabel(
                title: title,
                isRequired: isRequired,
                isError: isError,
                errorMessage: errorMessage
            )
            
            if isSecure {
                HStack {
                    if isPasswordVisible {
                        TextField(placeholder, text: $text)
                            .autocapitalization(autocapitalization)
                            .keyboardType(keyboardType)
                            .disableAutocorrection(true)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                    
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                .ptTextFieldStyle(isError: .constant(isError), isDisabled: isDisabled)
            } else {
                TextField(placeholder, text: $text)
                    .autocapitalization(autocapitalization)
                    .keyboardType(keyboardType)
                    .disableAutocorrection(true)
                    .ptTextFieldStyle(isError: .constant(isError), isDisabled: isDisabled)
            }
        }
    }
} 