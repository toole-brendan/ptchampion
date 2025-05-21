import SwiftUI
import PTDesignSystem

// Shadow size definition for ProfileView
fileprivate enum ProfileShadowSize {
    case small
    case medium
    case large
}

// Extension only for ProfileView
fileprivate extension View {
    func profileShadow(size: ProfileShadowSize = .medium) -> some View {
        self.shadow(
            color: Color.black.opacity(size == .small ? 0.1 : 0.15),
            radius: size == .small ? 4 : 8,
            x: 0,
            y: size == .small ? 2 : 4
        )
    }
}

// Top-level enum definitions for broader access
enum AppearanceSetting: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    var id: String { self.rawValue }
}

enum UnitSetting: String, CaseIterable, Identifiable {
    case metric = "Metric (kg, km)"
    case imperial = "Imperial (lbs, miles)"
    var id: String { self.rawValue }
}

/// Reusable header component for screen titles and subtitles with consistent height and positioning
struct ScreenHeader<TrailingContent: View>: View {
    let title: String
    let subtitle: String
    let trailingContent: TrailingContent
    
    init(title: String, subtitle: String, @ViewBuilder trailingContent: @escaping () -> TrailingContent = { EmptyView() }) {
        self.title = title
        self.subtitle = subtitle
        self.trailingContent = trailingContent()
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                Text(title)
                    .font(AppTheme.GeneratedTypography.heading(size: AppTheme.GeneratedTypography.body))
                    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.small))
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    .italic()
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            trailingContent
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppTheme.GeneratedSpacing.large)
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var fitnessDeviceManagerViewModel: FitnessDeviceManagerViewModel
    @Environment(\.colorScheme) var colorScheme 
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    // User information
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var username: String = ""
    @State private var email: String = ""
    
    // Password management
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var passwordsMatch: Bool = true
    
    // UI State
    @State private var isSubmitting = false
    @State private var isChangingPassword = false
    @State private var showSuccessMessage = false
    @State private var showPasswordSuccessMessage = false
    @State private var message: String? = nil
    @State private var passwordMessage: String? = nil
    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    @State private var showingSettings = false

    var body: some View {
        // Replace ScreenContainer with custom view matching WorkoutHistoryView style
        NavigationStack {
            ZStack {
                // Ambient Background Gradient
                RadialGradient(
                    gradient: Gradient(colors: [
                        AppTheme.GeneratedColors.background.opacity(0.9),
                        AppTheme.GeneratedColors.background
                    ]),
                    center: .center,
                    startRadius: 50,
                    endRadius: UIScreen.main.bounds.height * 0.6
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                        // Custom styled header matching WorkoutHistoryView
                        VStack(spacing: 16) {
                            HStack {
                                Text("PROFILE")
                                    .font(.system(size: 32, weight: .bold))
                                    .tracking(2)
                                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                
                                Spacer()
                                
                                // Add Settings button
                                Button {
                                    hapticGenerator.impactOccurred(intensity: 0.3)
                                    showingSettings = true
                                } label: {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Rectangle()
                                .frame(width: 120, height: 1.5)
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Edit Profile Section
                        profileEditSection
                        
                        // Password Management Section
                        passwordManagementSection
                        
                        // Logout Button (replaces Account Actions / Danger Zone section)
                        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                            Button {
                                hapticGenerator.impactOccurred(intensity: 0.5)
                                authViewModel.logout()
                                navigationState.navigateTo(.login)
                            } label: {
                                HStack {
                                    if false { // Placeholder for consistency with other buttons
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .padding(.trailing, 8)
                                    }
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .padding(.trailing, 4)
                                        .foregroundColor(AppTheme.GeneratedColors.error)
                                    Text("Log Out")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppTheme.GeneratedColors.error)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.GeneratedColors.deepOps)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppTheme.GeneratedColors.error, lineWidth: 1.5)
                                )
                            }
                            .padding(.top, 8)
                        }
                        .padding(.bottom, 8)
                    }
                    .padding(AppTheme.GeneratedSpacing.contentPadding)
                }
                
                // Success messages as toasts
                if showSuccessMessage {
                    VStack {
                        Spacer()
                        Text("Profile updated successfully")
                            .padding()
                            .background(AppTheme.GeneratedColors.success)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.bottom, 20)
                    }
                }
                
                if showPasswordSuccessMessage {
                    VStack {
                        Spacer()
                        Text("Password updated successfully")
                            .padding()
                            .background(AppTheme.GeneratedColors.success)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.bottom, 20)
                    }
                }
            }
        }
        .onAppear {
            hapticGenerator.prepare()
            loadUserData()
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                SettingsView()
                    .environmentObject(authViewModel)
                    .environmentObject(navigationState)
                    .environmentObject(fitnessDeviceManagerViewModel)
            }
        }
    }
    
    // MARK: - Profile Edit Section
    private var profileEditSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
            PTCard(style: .standard) {
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                            .font(.system(size: 20))
                        Text("Edit Profile")
                            .font(AppTheme.GeneratedTypography.heading(size: 18))
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    }
                    .padding(.bottom, 4)
                    
                    Text("Update your personal information.")
                        .font(AppTheme.GeneratedTypography.body(size: 14))
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    
                    // Display message if any
                    if let message = message {
                        Text(message)
                            .font(AppTheme.GeneratedTypography.body(size: 14))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(showSuccessMessage ? AppTheme.GeneratedColors.success.opacity(0.1) : AppTheme.GeneratedColors.error.opacity(0.1))
                            )
                            .foregroundColor(showSuccessMessage ? AppTheme.GeneratedColors.success : AppTheme.GeneratedColors.error)
                    }
                    
                    // First Name
                    VStack(alignment: .leading, spacing: 4) {
                        Text("First Name")
                            .font(AppTheme.GeneratedTypography.body(size: 14))
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        
                        TextField("Your first name", text: $firstName)
                            .font(.system(size: 16))
                            .padding()
                            .background(AppTheme.GeneratedColors.background)
                            .cornerRadius(8)
                            .disabled(isSubmitting)
                    }
                    
                    // Last Name
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Name")
                            .font(AppTheme.GeneratedTypography.body(size: 14))
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        
                        TextField("Your last name", text: $lastName)
                            .font(.system(size: 16))
                            .padding()
                            .background(AppTheme.GeneratedColors.background)
                            .cornerRadius(8)
                            .disabled(isSubmitting)
                    }
                    
                    // Username
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Username")
                            .font(AppTheme.GeneratedTypography.body(size: 14))
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        
                        TextField("Your unique username", text: $username)
                            .font(.system(size: 16))
                            .padding()
                            .background(AppTheme.GeneratedColors.background)
                            .cornerRadius(8)
                            .disabled(isSubmitting)
                    }
                    
                    // Email
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email")
                            .font(AppTheme.GeneratedTypography.body(size: 14))
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        
                        TextField("Your email address", text: $email)
                            .font(.system(size: 16))
                            .padding()
                            .background(AppTheme.GeneratedColors.background)
                            .cornerRadius(8)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disabled(isSubmitting)
                    }
                    
                    // Save button
                    Button {
                        saveProfile()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                            }
                            Text(isSubmitting ? "Saving..." : "Save Changes")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.GeneratedColors.deepOps)
                        .cornerRadius(8)
                    }
                    .disabled(isSubmitting || !formDataHasChanges())
                    .padding(.top, 8)
                }
                .padding()
            }
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Password Management Section
    private var passwordManagementSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
            PTCard(style: .standard) {
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                    HStack {
                        Image(systemName: "lock.circle")
                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                            .font(.system(size: 20))
                        Text("Password Management")
                            .font(AppTheme.GeneratedTypography.heading(size: 18))
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    }
                    .padding(.bottom, 4)
                    
                    Text("Update your password regularly for security.")
                        .font(AppTheme.GeneratedTypography.body(size: 14))
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    
                    // Display password message if any
                    if let passwordMessage = passwordMessage {
                        Text(passwordMessage)
                            .font(AppTheme.GeneratedTypography.body(size: 14))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(showPasswordSuccessMessage ? AppTheme.GeneratedColors.success.opacity(0.1) : AppTheme.GeneratedColors.error.opacity(0.1))
                            )
                            .foregroundColor(showPasswordSuccessMessage ? AppTheme.GeneratedColors.success : AppTheme.GeneratedColors.error)
                    }
                    
                    // New Password
                    VStack(alignment: .leading, spacing: 4) {
                        Text("New Password")
                            .font(AppTheme.GeneratedTypography.body(size: 14))
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        
                        SecureField("Enter new password", text: $newPassword)
                            .font(.system(size: 16))
                            .padding()
                            .background(AppTheme.GeneratedColors.background)
                            .cornerRadius(8)
                            .disabled(isChangingPassword)
                            .onChange(of: newPassword) { _, newValue in
                                validatePasswords()
                            }
                    }
                    
                    // Confirm Password
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Confirm Password")
                            .font(AppTheme.GeneratedTypography.body(size: 14))
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        
                        SecureField("Confirm new password", text: $confirmPassword)
                            .font(.system(size: 16))
                            .padding()
                            .background(AppTheme.GeneratedColors.background)
                            .cornerRadius(8)
                            .disabled(isChangingPassword)
                            .onChange(of: confirmPassword) { _, newValue in
                                validatePasswords()
                            }
                    }
                    
                    if !passwordsMatch && !newPassword.isEmpty && !confirmPassword.isEmpty {
                        Text("Passwords do not match")
                            .font(AppTheme.GeneratedTypography.body(size: 14))
                            .foregroundColor(AppTheme.GeneratedColors.error)
                    }
                    
                    // Change Password button
                    Button {
                        changePassword()
                    } label: {
                        HStack {
                            if isChangingPassword {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                            }
                            Text(isChangingPassword ? "Updating..." : "Change Password")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.GeneratedColors.deepOps)
                        .cornerRadius(8)
                    }
                    .disabled(isChangingPassword || newPassword.isEmpty || confirmPassword.isEmpty || !passwordsMatch)
                    .padding(.top, 8)
                }
                .padding()
            }
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Helper Methods
    private func loadUserData() {
        if case .authenticated(let user) = authViewModel.authState {
            firstName = user.firstName ?? ""
            lastName = user.lastName ?? ""
            username = user.username ?? ""
            email = user.email ?? ""
        }
    }
    
    private func saveProfile() {
        hapticGenerator.impactOccurred(intensity: 0.5)
        isSubmitting = true
        message = nil
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isSubmitting = false
            self.showSuccessMessage = true
            self.message = "Profile updated successfully"
            
            // Update auth view model with new data
            if case .authenticated(var user) = self.authViewModel.authState {
                user.firstName = self.firstName
                user.lastName = self.lastName
                user.username = self.username
                user.email = self.email
                // Update the auth state with the modified user
                self.authViewModel.setMockUser(user)
            }
            
            // Auto-dismiss success message
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.showSuccessMessage = false
                self.message = nil
            }
        }
    }
    
    private func validatePasswords() {
        passwordsMatch = newPassword == confirmPassword
    }
    
    private func changePassword() {
        hapticGenerator.impactOccurred(intensity: 0.5)
        
        // Validate passwords
        if newPassword.isEmpty {
            passwordMessage = "Please enter a new password"
            return
        }
        
        if !passwordsMatch {
            passwordMessage = "Passwords do not match"
            return
        }
        
        isChangingPassword = true
        passwordMessage = nil
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isChangingPassword = false
            self.showPasswordSuccessMessage = true
            self.passwordMessage = "Password updated successfully"
            
            // Reset password fields
            self.newPassword = ""
            self.confirmPassword = ""
            
            // Auto-dismiss success message
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.showPasswordSuccessMessage = false
                self.passwordMessage = nil
            }
        }
    }
    
    // Compares form data with original user data to see if anything changed
    private func formDataHasChanges() -> Bool {
        guard case .authenticated(let user) = authViewModel.authState else { return false }
        
        return (
            firstName != (user.firstName ?? "") ||
            lastName != (user.lastName ?? "") ||
            username != (user.username ?? "") ||
            email != (user.email ?? "")
        )
    }
}

// Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView()
                .environmentObject(MockAuthViewModel())
        }
    }
}

// Mock AuthViewModel for Previews
class MockAuthViewModel: AuthViewModel {
    override init() {
        super.init()
        let mockUser = AuthUserModel(
            id: "mockUserID123",
            email: "user@example.com",
            firstName: "Preview",
            lastName: "User",
            profilePictureUrl: nil
        )
        self.setMockUser(mockUser)
    }
} 