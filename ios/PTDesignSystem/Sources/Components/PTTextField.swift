import SwiftUI
import DesignTokens
import Introspect

// iOS 15+ specific modifier extension
struct iOS15ModifierWrapper: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content.textInputAutocapitalization(.never)
        } else {
            content
        }
    }
}

// Safe extension for iOS 15+ features
extension View {
    func iOS15TextInputAutocapitalization() -> some View {
        self.modifier(iOS15ModifierWrapper())
    }
}

public struct PTTextField: View {
    private let placeholder: String
    private let isSecure: Bool
    @Binding private var text: String
    private var label: String?
    private var icon: Image?
    private var keyboardType: UIKeyboardType
    
    public init(_ placeholder: String, text: Binding<String>, isSecure: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.label = nil
        self.icon = nil
        self.keyboardType = .default
    }
    
    public init(_ placeholder: String,
                text: Binding<String>,
                label: String? = nil,
                isSecure: Bool = false,
                icon: Image? = nil,
                keyboardType: UIKeyboardType = .default) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.label = label
        self.icon = icon
        self.keyboardType = keyboardType
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !text.isEmpty || label != nil {
                Text(label ?? placeholder)
                    .font(.caption)
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
            }
            
            HStack {
                Group {
                    if isSecure {
                        SecureField(text.isEmpty ? placeholder : "", text: $text)
                            .introspectTextField { textField in
                                #if DEBUG
                                print("🪄 Introspected:", textField)
                                #endif
                                let item = textField.inputAssistantItem
                                item.leadingBarButtonGroups  = []
                                item.trailingBarButtonGroups = []

                                if textField.inputAccessoryView == nil {
                                    textField.inputAccessoryView = UIView(frame: .zero)
                                }
                            }
                    } else {
                        TextField(text.isEmpty ? placeholder : "", text: $text)
                            .introspectTextField { textField in
                                #if DEBUG
                                print("🪄 Introspected:", textField)
                                #endif
                                let item = textField.inputAssistantItem
                                item.leadingBarButtonGroups  = []
                                item.trailingBarButtonGroups = []

                                if textField.inputAccessoryView == nil {
                                    textField.inputAccessoryView = UIView(frame: .zero)
                                }
                            }
                    }
                }
                .keyboardType(keyboardType)
                .disableAutocorrection(true)
                .autocapitalization(.none)                    // iOS 13+
                .iOS15TextInputAutocapitalization()           // Safe iOS 15+ wrapper
                
                if let icon = icon {
                    icon
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
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

public struct PTTextField_Previews: PreviewProvider {
    public static var previews: some View {
        VStack(spacing: 20) {
            PTTextField("Email", text: .constant(""))
            
            PTTextField("Email", text: .constant("user@example.com"))
            
            PTTextField("Password", text: .constant(""), isSecure: true)
            
            PTTextField("Email Address", 
                       text: .constant(""), 
                       label: "Email", 
                       icon: Image(systemName: "envelope"),
                       keyboardType: .emailAddress)
            
            PTTextField("Secret Code", 
                       text: .constant("1234"), 
                       label: "Code", 
                       isSecure: true, 
                       icon: Image(systemName: "lock.shield"),
                       keyboardType: .numberPad)
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