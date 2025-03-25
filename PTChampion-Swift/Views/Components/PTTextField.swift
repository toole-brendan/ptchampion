import SwiftUI

struct PTTextField: View {
    var title: String
    var placeholder: String
    var text: Binding<String>
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .none
    var icon: String? = nil
    var errorMessage: String? = nil
    
    @State private var isShowingPassword: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Field label
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            // Input field
            HStack(spacing: 10) {
                // Optional icon
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.gray)
                }
                
                // Secure or regular text field
                if isSecure && !isShowingPassword {
                    SecureField(placeholder, text: text)
                        .autocapitalization(autocapitalization)
                        .keyboardType(keyboardType)
                } else {
                    TextField(placeholder, text: text)
                        .autocapitalization(autocapitalization)
                        .keyboardType(keyboardType)
                }
                
                // Show/hide password button for secure fields
                if isSecure {
                    Button(action: {
                        isShowingPassword.toggle()
                    }) {
                        Image(systemName: isShowingPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .frame(height: 50)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(errorMessage != nil ? Color.red : Color.clear, lineWidth: 1)
            )
            
            // Error message (if present)
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 4)
            }
        }
    }
}

// Preview
struct PTTextField_Previews: PreviewProvider {
    @State static var text = ""
    @State static var password = "password123"
    
    static var previews: some View {
        VStack(spacing: 20) {
            PTTextField(
                title: "Username",
                placeholder: "Enter your username",
                text: $text,
                icon: "person.fill"
            )
            
            PTTextField(
                title: "Email",
                placeholder: "Enter your email",
                text: $text,
                keyboardType: .emailAddress,
                icon: "envelope.fill"
            )
            
            PTTextField(
                title: "Password",
                placeholder: "Enter your password",
                text: $password,
                isSecure: true,
                icon: "lock.fill"
            )
            
            PTTextField(
                title: "Username",
                placeholder: "Enter your username",
                text: $text,
                icon: "person.fill",
                errorMessage: "Username is required"
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}