import SwiftUI

struct PTTextField: View {
    let title: String
    let placeholder: String
    let text: Binding<String>
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default
    ) {
        self.title = title
        self.placeholder = placeholder
        self.text = text
        self.isSecure = isSecure
        self.keyboardType = keyboardType
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            if isSecure {
                SecureField(placeholder, text: text)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .keyboardType(keyboardType)
            } else {
                TextField(placeholder, text: text)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .keyboardType(keyboardType)
            }
        }
    }
}

// Preview
struct PTTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PTTextField(
                title: "Email",
                placeholder: "Enter your email",
                text: .constant("user@example.com")
            )
            
            PTTextField(
                title: "Password",
                placeholder: "Enter your password",
                text: .constant("password123"),
                isSecure: true
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}