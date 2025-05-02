import SwiftUI
import Foundation

struct RegistrationView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    
    // Form fields
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    
    // UI state
    @State private var isLoading = false
    @State private var passwordMismatch = false
    @State private var keyboardHeight: CGFloat = 0
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty &&
        !firstName.isEmpty && !lastName.isEmpty && password == confirmPassword
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Logo
                Image(uiImage: UIImage(named: "pt_champion_logo") ?? 
                      (Bundle.main.path(forResource: "pt_champion_logo", ofType: "png").flatMap { UIImage(contentsOfFile: $0) }) ?? 
                      UIImage(systemName: "shield.lefthalf.filled")!)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(Color("BrassGold"))
                    .padding(.top, 40)
                
                Text("Create Account")
                    .font(.custom("BebasNeue-Bold", size: 36))
                    .foregroundColor(Color("CommandBlack"))
                    .padding(.bottom, 10)
                
                // Form fields with consistent styling
                VStack(spacing: 16) {
                    PTTextField(
                        placeholder: "First Name",
                        text: $firstName
                    )
                    
                    PTTextField(
                        placeholder: "Last Name",
                        text: $lastName
                    )
                    
                    PTTextField(
                        placeholder: "Email",
                        text: $email,
                        keyboardType: .emailAddress
                    )
                    
                    PTTextField(
                        placeholder: "Password",
                        text: $password,
                        isSecure: true
                    )
                    .onChange(of: password) { _, _ in validatePasswords() }
                    
                    PTTextField(
                        placeholder: "Confirm Password",
                        text: $confirmPassword,
                        isSecure: true
                    )
                    .onChange(of: confirmPassword) { _, _ in validatePasswords() }
                    
                    if passwordMismatch {
                        Text("Passwords do not match.")
                            .foregroundColor(.red)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                    
                    if let errorMessage = auth.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 5)
                    }
                    
                    if let successMessage = auth.successMessage {
                         Text(successMessage)
                             .foregroundColor(.green)
                             .font(.caption)
                             .padding(.top, 5)
                    }
                    
                    // Register button
                    Button(action: {
                        auth.errorMessage = nil
                        isLoading = true
                        
                        // Create display name from first and last name
                        let displayName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if validatePasswords() {
                            auth.register(username: email,
                                                  password: password,
                                                  displayName: displayName)
                        }
                        
                        // Add haptic feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }) {
                        if auth.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color("Cream")))
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("CREATE ACCOUNT")
                                .font(.custom("Montserrat-Bold", size: 16))
                                .foregroundColor(Color("Cream"))
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(isFormValid ? Color("BrassGold") : Color.gray.opacity(0.5))
                    .cornerRadius(8)
                    .disabled(!isFormValid || auth.isLoading)
                    .padding(.top, 10)
                    
                    // Back to login button
                    Button(action: {
                        // Use dismiss instead of navigationState
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                                .font(.caption)
                            Text("Back to Login")
                                .font(.custom("Montserrat-Medium", size: 14))
                        }
                        .foregroundColor(Color("BrassGold"))
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .frame(minHeight: UIScreen.main.bounds.height - keyboardHeight)
            .padding(.bottom, keyboardHeight)
        }
        .background(Color("Cream").ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            // Set up keyboard notifications
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                    keyboardHeight = keyboardSize.height
                }
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                keyboardHeight = 0
            }
            
            // Clear any previous messages
            clearMessages()
        }
        .onChange(of: auth.successMessage) { _, newValue in
            if let success = newValue, !success.isEmpty {
                // If registration was successful, navigate back to login after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    // Just dismiss this view to go back to login
                    dismiss()
                }
            }
        }
    }
    
    private func validatePasswords() -> Bool {
        if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
            passwordMismatch = true
            return false
        } else {
            passwordMismatch = false
            return true
        }
    }
    
    private func clearMessages() {
         auth.errorMessage = nil
         auth.successMessage = nil
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    NavigationView {
        RegistrationView()
            .environmentObject(AuthViewModel())
    }
} 