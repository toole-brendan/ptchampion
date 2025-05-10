import SwiftUI
import PTDesignSystem

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // User information
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    
    // UI State
    @State private var isLoading = false
    @State private var showSuccessToast = false
    @State private var formErrors: [String: String] = [:]
    @State private var focusedField: FormField? = nil
    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // Form field identifiers for focus state
    enum FormField: Hashable {
        case firstName
        case lastName
        case email
    }
    
    var body: some View {
        ZStack {
            // Main Content
            ScrollView {
                VStack(spacing: AppTheme.GeneratedSpacing.large) {
                    // Form Content in Cards
                    formContent
                    
                    // Save Button (Additional to the one in navbar)
                    saveButton
                        .padding(.top, AppTheme.GeneratedSpacing.large)
                        .padding(.bottom, AppTheme.GeneratedSpacing.section)
                }
                .padding(AppTheme.GeneratedSpacing.contentPadding)
            }
            .background(AppTheme.GeneratedColors.background.ignoresSafeArea())
            
            // Success Toast
            if showSuccessToast {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        
                        Text("Profile updated successfully")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(AppTheme.GeneratedColors.success)
                            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    )
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .zIndex(100)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Cancel button
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    hapticGenerator.impactOccurred(intensity: 0.4)
                    dismiss()
                }
                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
            }
            
            // Save button
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    hapticGenerator.impactOccurred(intensity: 0.6)
                    saveProfile()
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(AppTheme.GeneratedColors.accent)
                    } else {
                        Text("Save")
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.GeneratedColors.accent)
                    }
                }
                .disabled(isLoading || !isFormValid)
            }
        }
        .onAppear {
            loadCurrentUserData()
            hapticGenerator.prepare()
        }
    }
    
    // MARK: - Subviews
    
    // Form Content
    private var formContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
            // Section Header
            Text("Personal Information")
                .font(.title3.weight(.semibold))
                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                .padding(.leading, 4)
                .accessibilityAddTraits(.isHeader)
            
            // Personal Info Card
            personalInfoCard
        }
    }
    
    // Personal Info Card
    private var personalInfoCard: some View {
        PTCard {
            VStack(spacing: 0) {
                // First Name Field
                formField(
                    label: "First Name",
                    iconName: "person.fill",
                    text: $firstName,
                    placeholder: "Enter your first name",
                    error: formErrors["firstName"],
                    field: .firstName
                )
                
                Divider()
                    .padding(.leading, 56)
                
                // Last Name Field
                formField(
                    label: "Last Name",
                    iconName: "person.fill",
                    text: $lastName,
                    placeholder: "Enter your last name",
                    error: formErrors["lastName"],
                    field: .lastName
                )
                
                Divider()
                    .padding(.leading, 56)
                
                // Email Field
                formField(
                    label: "Email",
                    iconName: "envelope.fill",
                    text: $email,
                    placeholder: "Enter your email",
                    error: formErrors["email"],
                    keyboardType: .emailAddress,
                    field: .email
                )
            }
        }
    }
    
    // Save Button 
    private var saveButton: some View {
        Button {
            hapticGenerator.impactOccurred(intensity: 0.6)
            saveProfile()
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Save Changes")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isFormValid ? 
                    AppTheme.GeneratedColors.brassGold : 
                    AppTheme.GeneratedColors.brassGold.opacity(0.3)
            )
            .cornerRadius(AppTheme.GeneratedRadius.button)
        }
        .disabled(isLoading || !isFormValid)
    }
    
    // Reusable Form Field Component
    private func formField(
        label: String,
        iconName: String,
        text: Binding<String>,
        placeholder: String,
        error: String? = nil,
        keyboardType: UIKeyboardType = .default,
        field: FormField
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: AppTheme.GeneratedSpacing.medium) {
                // Icon
                Image(systemName: iconName)
                    .frame(width: 24)
                    .foregroundColor(focusedField == field ? AppTheme.GeneratedColors.brassGold : AppTheme.GeneratedColors.textSecondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    // Label
                    Text(label)
                        .font(.caption)
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    
                    // Text Field
                    TextField(placeholder, text: text)
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: text.wrappedValue) { _ in
                            validateField(field)
                        }
                        .onTapGesture {
                            focusedField = field
                        }
                }
            }
            .frame(height: 60)
            .contentShape(Rectangle())
            
            // Error Message (if any)
            if let error = error, !error.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundColor(AppTheme.GeneratedColors.error)
                    .padding(.leading, 56)
                    .transition(.opacity)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Load current user data
    private func loadCurrentUserData() {
        // Populate fields with current user data
        if let user = authViewModel.currentUser {
            firstName = user.firstName ?? ""
            lastName = user.lastName ?? ""
            email = user.email
        }
    }
    
    // Validate a specific field
    private func validateField(_ field: FormField) {
        switch field {
        case .firstName:
            if firstName.isEmpty {
                formErrors["firstName"] = "First name is required"
            } else {
                formErrors.removeValue(forKey: "firstName")
            }
        case .lastName:
            if lastName.isEmpty {
                formErrors["lastName"] = "Last name is required"
            } else {
                formErrors.removeValue(forKey: "lastName")
            }
        case .email:
            if email.isEmpty {
                formErrors["email"] = "Email is required"
            } else if !isValidEmail(email) {
                formErrors["email"] = "Please enter a valid email"
            } else {
                formErrors.removeValue(forKey: "email")
            }
        }
    }
    
    // Validate all fields
    private func validateAllFields() -> Bool {
        validateField(.firstName)
        validateField(.lastName)
        validateField(.email)
        
        return formErrors.isEmpty
    }
    
    // Check if the form is valid
    private var isFormValid: Bool {
        return !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && isValidEmail(email)
    }
    
    // Email validation
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    // Save profile changes
    private func saveProfile() {
        // Validate all fields first
        guard validateAllFields() else {
            // Show error animation for fields with errors
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                // This could be more complex animation if needed
            }
            return
        }
        
        // Set loading state
        isLoading = true
        
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Here you would normally call your API to update the profile
            // For now, we'll just simulate a successful update
            
            // Update the user in your view model
            self.authViewModel.updateUserProfile(
                firstName: self.firstName,
                lastName: self.lastName,
                email: self.email
            )
            
            // Reset loading state
            self.isLoading = false
            
            // Show success toast
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                self.showSuccessToast = true
            }
            
            // Hide success toast after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    self.showSuccessToast = false
                }
                
                // Dismiss the view after the toast is hidden
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.dismiss()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EditProfileView()
            .environmentObject(MockAuthViewModel())
    }
    .environment(\.colorScheme, .light)
} 