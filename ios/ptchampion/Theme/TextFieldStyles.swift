import SwiftUI

struct PTTextFieldStyle: ViewModifier {
    @Binding var isError: Bool
    var isDisabled: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .font(AppTheme.GeneratedTypography.body())
            .background(isDisabled ? AppTheme.GeneratedColors.tacticalGray.opacity(0.1) : AppTheme.GeneratedColors.cream)
            .foregroundColor(isDisabled ? AppTheme.GeneratedColors.tacticalGray : AppTheme.GeneratedColors.textPrimary)
            .cornerRadius(AppTheme.GeneratedRadius.input)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.input)
                    .stroke(
                        isError ? AppTheme.GeneratedColors.error : 
                                  AppTheme.GeneratedColors.armyTan.opacity(0.5),
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
                    .font(AppTheme.GeneratedTypography.bodySemiBold())
                    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                
                if isRequired {
                    Text("*")
                        .font(AppTheme.GeneratedTypography.bodySemiBold())
                        .foregroundColor(AppTheme.GeneratedColors.error)
                }
            }
            
            if isError && errorMessage != nil {
                Text(errorMessage!)
                    .font(AppTheme.GeneratedTypography.body(size: 12))
                    .foregroundColor(AppTheme.GeneratedColors.error)
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
    var focusState: FocusState<Bool>.Binding? = nil
    
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
                            .if(focusState != nil) { view in
                                if #available(iOS 15.0, *), let focusState = focusState {
                                    view.focused(focusState)
                                } else {
                                    view
                                }
                            }
                    } else {
                        SecureField(placeholder, text: $text)
                            .if(focusState != nil) { view in
                                if #available(iOS 15.0, *), let focusState = focusState {
                                    view.focused(focusState)
                                } else {
                                    view
                                }
                            }
                    }
                    
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    }
                }
                .ptTextFieldStyle(isError: .constant(isError), isDisabled: isDisabled)
            } else {
                TextField(placeholder, text: $text)
                    .autocapitalization(autocapitalization)
                    .keyboardType(keyboardType)
                    .disableAutocorrection(true)
                    .if(focusState != nil) { view in
                        if #available(iOS 15.0, *), let focusState = focusState {
                            view.focused(focusState)
                        } else {
                            view
                        }
                    }
                    .ptTextFieldStyle(isError: .constant(isError), isDisabled: isDisabled)
            }
        }
    }
}

// Helper extension for conditional modifiers
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
} 