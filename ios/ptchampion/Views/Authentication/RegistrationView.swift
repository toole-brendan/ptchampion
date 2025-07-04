import SwiftUI
import Foundation
import PTDesignSystem

struct RegistrationView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var navigationState: NavigationState
    @EnvironmentObject var tabBarVisibility: TabBarVisibilityManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    
    // Form fields
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var gender = ""
    @State private var dateOfBirth = Date()
    
    // UI state
    @State private var isLoading = false
    @State private var passwordMismatch = false
    @State private var passwordTooShort = false
    @State private var keyboardHeight: CGFloat = 0
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty &&
        !firstName.isEmpty && !lastName.isEmpty && !username.isEmpty &&
        password == confirmPassword && password.count >= 8
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.GeneratedSpacing.large) {
                // Logo - fix the ambiguous init by being more explicit
                let logoImage: UIImage = {
                    if let named = UIImage(named: "pt_champion_logo") {
                        return named
                    } else if let path = Bundle.main.path(forResource: "pt_champion_logo", ofType: "png"),
                              let img = UIImage(contentsOfFile: path) {
                        return img
                    } else {
                        return UIImage(systemName: "shield.lefthalf.filled") ?? UIImage()
                    }
                }()
                
                Image(uiImage: logoImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    .padding(.top, 20)
                
                PTLabel("Create Account", style: .heading)
                    .foregroundColor(AppTheme.GeneratedColors.commandBlack)
                    .padding(.bottom, 10)
                
                // Form fields with consistent styling
                VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                    PTTextField(
                        "",
                        text: $firstName,
                        label: "FIRST NAME",
                        icon: Image(systemName: "person")
                    )
                    
                    PTTextField(
                        "",
                        text: $lastName,
                        label: "LAST NAME",
                        icon: Image(systemName: "person.2")
                    )
                    
                    PTTextField(
                        "",
                        text: $email,
                        label: "EMAIL",
                        icon: Image(systemName: "envelope"),
                        keyboardType: .emailAddress
                    )
                    
                    PTTextField(
                        "",
                        text: $username,
                        label: "USERNAME",
                        icon: Image(systemName: "person.text.rectangle")
                    )
                    
                    // Gender selection
                    VStack(alignment: .leading, spacing: 4) {
                        PTLabel("GENDER (OPTIONAL - FOR USMC PFT SCORING)", style: .caption)
                            .foregroundColor(AppTheme.GeneratedColors.commandBlack)
                        
                        HStack(spacing: 16) {
                            ForEach(["male", "female"], id: \.self) { option in
                                Button(action: {
                                    gender = option
                                }) {
                                    HStack {
                                        Image(systemName: gender == option ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(gender == option ? AppTheme.GeneratedColors.brassGold : AppTheme.GeneratedColors.tacticalGray)
                                        PTLabel(option.capitalized, style: .body)
                                            .foregroundColor(AppTheme.GeneratedColors.commandBlack)
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Date of Birth
                    VStack(alignment: .leading, spacing: 4) {
                        PTLabel("DATE OF BIRTH (OPTIONAL - FOR AGE-BASED SCORING)", style: .caption)
                            .foregroundColor(AppTheme.GeneratedColors.commandBlack)
                        
                        DatePicker("", selection: $dateOfBirth, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .labelsHidden()
                            .accentColor(AppTheme.GeneratedColors.brassGold)
                    }
                    
                    PTTextField(
                        "",
                        text: $password,
                        label: "PASSWORD",
                        isSecure: true,
                        icon: Image(systemName: "lock")
                    )
                    .onChange(of: password) { _, _ in validatePasswords() }
                    
                    PTTextField(
                        "",
                        text: $confirmPassword,
                        label: "CONFIRM PASSWORD",
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
                    
                    if passwordTooShort {
                        PTLabel("Password must be at least 8 characters.", style: .caption)
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
                        // Use a typed local variable to resolve ambiguity
                        let coreButtonStyle: PTButton.ButtonStyle = .primary
                        PTButton("CREATE ACCOUNT", style: coreButtonStyle, isLoading: true) {}
                            .disabled(true)
                            .padding(.top, 10)
                    } else {
                        // Use a typed local variable to resolve ambiguity
                        let coreButtonStyle: PTButton.ButtonStyle = .primary
                        PTButton("CREATE ACCOUNT", style: coreButtonStyle) {
                            auth.errorMessage = nil
                            isLoading = true
                            
                            if validatePasswords() {
                                auth.register(
                                    email: email,
                                    password: password,
                                    firstName: firstName,
                                    lastName: lastName,
                                    username: username
                                )
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
                    let secondaryButtonStyle: PTButton.ButtonStyle = .secondary
                    PTButton("Back to Login", style: secondaryButtonStyle, icon: Image(systemName: "arrow.left")) {
                        // Show tab bar when navigating back
                        tabBarVisibility.showTabBar()
                        // Use NavigationState to navigate back to login
                        navigationState.navigateTo(.login)
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
            // Hide tab bar on registration screen
            tabBarVisibility.hideTabBar()
            
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
                    // Show tab bar when navigating back
                    tabBarVisibility.showTabBar()
                    // Use NavigationState instead of dismiss
                    navigationState.navigateTo(.login)
                }
            }
        }
    }
    
    private func validatePasswords() -> Bool {
        passwordTooShort = false

        if password.count < 8 && !password.isEmpty {
            passwordTooShort = true
        }

        if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
            passwordMismatch = true
            return false
        } else {
            passwordMismatch = false
            return !passwordTooShort
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