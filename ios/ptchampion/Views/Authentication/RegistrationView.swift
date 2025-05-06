import SwiftUI
import Foundation
import PTDesignSystem

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
            VStack(spacing: AppTheme.GeneratedSpacing.large) {
                // Logo
                Image(uiImage: UIImage(named: "pt_champion_logo") ?? 
                      (Bundle.main.path(forResource: "pt_champion_logo", ofType: "png").flatMap { UIImage(contentsOfFile: $0) }) ?? 
                      UIImage(systemName: "shield.lefthalf.filled")!)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    .padding(.top, 40)
                
                PTLabel("Create Account", style: .heading)
                    .foregroundColor(AppTheme.GeneratedColors.commandBlack)
                    .padding(.bottom, 10)
                
                // Form fields with consistent styling
                VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                    FocusableTextField(
                        "First Name",
                        text: $firstName,
                        icon: Image(systemName: "person")
                    )
                    
                    FocusableTextField(
                        "Last Name",
                        text: $lastName,
                        icon: Image(systemName: "person.2")
                    )
                    
                    FocusableTextField(
                        "Email",
                        text: $email,
                        keyboardType: .emailAddress,
                        icon: Image(systemName: "envelope")
                    )
                    
                    FocusableTextField(
                        "Password",
                        text: $password,
                        isSecure: true,
                        icon: Image(systemName: "lock")
                    )
                    .onChange(of: password) { _, _ in validatePasswords() }
                    
                    FocusableTextField(
                        "Confirm Password",
                        text: $confirmPassword,
                        isSecure: true,
                        icon: Image(systemName: "lock.shield")
                    )
                    .onChange(of: confirmPassword) { _, _ in validatePasswords() }
                    
                    if passwordMismatch {
                        PTLabel("Passwords do not match.", style: .caption)
                            .foregroundColor(AppTheme.GeneratedColors.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                    
                    if let errorMessage = auth.errorMessage {
                        PTLabel(errorMessage, style: .caption)
                            .foregroundColor(AppTheme.GeneratedColors.error)
                            .padding(.top, 5)
                    }
                    
                    if let successMessage = auth.successMessage {
                        PTLabel(successMessage, style: .bodyBold)
                            .foregroundColor(AppTheme.GeneratedColors.success)
                            .padding(.vertical, AppTheme.GeneratedSpacing.small)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(AppTheme.GeneratedColors.success.opacity(0.1))
                            .cornerRadius(AppTheme.GeneratedRadius.medium)
                            .padding(.top, 5)
                    }
                    
                    // Register button
                    if auth.isLoading {
                        PTButton("CREATE ACCOUNT", isLoading: true) {}
                            .disabled(true)
                            .padding(.top, 10)
                    } else {
                        PTButton("CREATE ACCOUNT") {
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
                        }
                        .disabled(!isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.5)
                        .padding(.top, 10)
                    }
                    
                    // Back to login button
                    PTButton("Back to Login", style: .secondary, icon: Image(systemName: "arrow.left")) {
                        // Use dismiss instead of navigationState
                        dismiss()
                    }
                    .padding(.vertical, 4) // Add smaller padding to simulate the small size
                    .padding(.top, 8)
                }
                .padding(.horizontal, AppTheme.GeneratedSpacing.medium)
                
                Spacer()
            }
            .frame(minHeight: UIScreen.main.bounds.height - keyboardHeight)
            .padding(.bottom, keyboardHeight)
        }
        .background(AppTheme.GeneratedColors.cream.ignoresSafeArea())
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
            .environment(\.colorScheme, .light)
    }
}

#Preview("Dark Mode") {
    NavigationView {
        RegistrationView()
            .environmentObject(AuthViewModel())
            .environment(\.colorScheme, .dark)
    }
} 