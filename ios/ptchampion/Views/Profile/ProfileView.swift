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
    
    // Animation states
    @State private var headerVisible = false
    @State private var sectionsVisible = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Ambient Background Gradient - matching Dashboard and WorkoutHistory
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
                        // Updated header matching WorkoutHistoryView style
                        VStack(spacing: 16) {
                            HStack {
                                Text("PROFILE")
                                    .font(.system(size: 32, weight: .bold))
                                    .tracking(2)
                                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                
                                Spacer()
                                
                                // Settings button
                                Button {
                                    hapticGenerator.impactOccurred(intensity: 0.3)
                                    showingSettings = true
                                } label: {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(AppTheme.GeneratedColors.brassGold.opacity(0.1))
                                        )
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Rectangle()
                                .frame(width: 120, height: 1.5)
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("MANAGE YOUR ACCOUNT")
                                .font(.system(size: 16, weight: .regular))
                                .tracking(1.5)
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                        .opacity(headerVisible ? 1 : 0)
                        .offset(y: headerVisible ? 0 : 10)
                        
                        // Edit Profile Section - Dashboard style
                        profileEditSection
                            .opacity(sectionsVisible ? 1 : 0)
                            .offset(y: sectionsVisible ? 0 : 15)
                        
                        // Password Management Section - Dashboard style
                        passwordManagementSection
                            .opacity(sectionsVisible ? 1 : 0)
                            .offset(y: sectionsVisible ? 0 : 15)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1), value: sectionsVisible)
                        
                        // Account Actions Section - Dashboard style
                        accountActionsSection
                            .opacity(sectionsVisible ? 1 : 0)
                            .offset(y: sectionsVisible ? 0 : 15)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2), value: sectionsVisible)
                    }
                    .padding(AppTheme.GeneratedSpacing.contentPadding)
                }
                
                // Success messages as toasts
                if showSuccessMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text("Profile updated successfully")
                                .foregroundColor(.white)
                                .font(AppTheme.GeneratedTypography.bodyBold())
                        }
                        .padding()
                        .background(AppTheme.GeneratedColors.success)
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .padding(.bottom, 20)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                if showPasswordSuccessMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text("Password updated successfully")
                                .foregroundColor(.white)
                                .font(AppTheme.GeneratedTypography.bodyBold())
                        }
                        .padding()
                        .background(AppTheme.GeneratedColors.success)
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .padding(.bottom, 20)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .contentContainer()
        .onAppear {
            hapticGenerator.prepare()
            loadUserData()
            animateContentIn()
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
        VStack(alignment: .leading, spacing: 0) {
            // Dark header with brass-gold text
            VStack(alignment: .leading, spacing: 4) {
                Text("EDIT PROFILE")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                    .padding(.bottom, 4)
                
                Text("UPDATE YOUR PERSONAL INFORMATION")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.GeneratedColors.deepOps)
            .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))
            
            // Light content area
            VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                // Display message if any
                if let message = message {
                    HStack {
                        Image(systemName: showSuccessMessage ? "checkmark.circle" : "exclamationmark.circle")
                            .foregroundColor(showSuccessMessage ? AppTheme.GeneratedColors.success : AppTheme.GeneratedColors.error)
                        Text(message)
                            .font(AppTheme.GeneratedTypography.body())
                            .foregroundColor(showSuccessMessage ? AppTheme.GeneratedColors.success : AppTheme.GeneratedColors.error)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(showSuccessMessage ? AppTheme.GeneratedColors.success.opacity(0.1) : AppTheme.GeneratedColors.error.opacity(0.1))
                    )
                }
                
                // Form fields with consistent styling
                VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                    formField(title: "FIRST NAME", text: $firstName, placeholder: "Your first name")
                    formField(title: "LAST NAME", text: $lastName, placeholder: "Your last name")
                    formField(title: "USERNAME", text: $username, placeholder: "Your unique username")
                    formField(title: "EMAIL", text: $email, placeholder: "Your email address", keyboardType: .emailAddress)
                }
                
                // Save button - matching dashboard style
                Button {
                    saveProfile()
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.GeneratedColors.brassGold))
                                .scaleEffect(0.8)
                                .padding(.trailing, 8)
                        }
                        Text(isSubmitting ? "SAVING..." : "SAVE CHANGES")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.GeneratedColors.deepOps)
                    .cornerRadius(8)
                }
                .disabled(isSubmitting || !formDataHasChanges())
                .opacity((!isSubmitting && formDataHasChanges()) ? 1 : 0.6)
            }
            .padding()
            .background(Color(red: 0.93, green: 0.91, blue: 0.86)) // cream-dark from web
            .clipShape(RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight]))
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Password Management Section
    private var passwordManagementSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Dark header
            VStack(alignment: .leading, spacing: 4) {
                Text("PASSWORD MANAGEMENT")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                    .padding(.bottom, 4)
                
                Text("UPDATE YOUR PASSWORD REGULARLY FOR SECURITY")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.GeneratedColors.deepOps)
            .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))
            
            // Light content area
            VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                // Display password message if any
                if let passwordMessage = passwordMessage {
                    HStack {
                        Image(systemName: showPasswordSuccessMessage ? "checkmark.circle" : "exclamationmark.circle")
                            .foregroundColor(showPasswordSuccessMessage ? AppTheme.GeneratedColors.success : AppTheme.GeneratedColors.error)
                        Text(passwordMessage)
                            .font(AppTheme.GeneratedTypography.body())
                            .foregroundColor(showPasswordSuccessMessage ? AppTheme.GeneratedColors.success : AppTheme.GeneratedColors.error)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(showPasswordSuccessMessage ? AppTheme.GeneratedColors.success.opacity(0.1) : AppTheme.GeneratedColors.error.opacity(0.1))
                    )
                }
                
                // Password fields
                VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                    secureFormField(title: "NEW PASSWORD", text: $newPassword, placeholder: "Enter new password")
                    secureFormField(title: "CONFIRM PASSWORD", text: $confirmPassword, placeholder: "Confirm new password")
                }
                
                if !passwordsMatch && !newPassword.isEmpty && !confirmPassword.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 14))
                        Text("Passwords do not match")
                            .font(AppTheme.GeneratedTypography.caption())
                    }
                    .foregroundColor(AppTheme.GeneratedColors.error)
                }
                
                // Change Password button
                Button {
                    changePassword()
                } label: {
                    HStack {
                        if isChangingPassword {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.GeneratedColors.brassGold))
                                .scaleEffect(0.8)
                                .padding(.trailing, 8)
                        }
                        Text(isChangingPassword ? "UPDATING..." : "CHANGE PASSWORD")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.GeneratedColors.deepOps)
                    .cornerRadius(8)
                }
                .disabled(isChangingPassword || newPassword.isEmpty || confirmPassword.isEmpty || !passwordsMatch)
                .opacity((newPassword.isEmpty || confirmPassword.isEmpty || !passwordsMatch || isChangingPassword) ? 0.6 : 1)
            }
            .padding()
            .background(Color(red: 0.93, green: 0.91, blue: 0.86))
            .clipShape(RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight]))
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Account Actions Section
    private var accountActionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Dark header
            VStack(alignment: .leading, spacing: 4) {
                Text("ACCOUNT ACTIONS")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                    .padding(.bottom, 4)
                
                Text("MANAGE YOUR ACCOUNT SESSION")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.GeneratedColors.deepOps)
            .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))
            
            // Light content area with logout button
            VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                Button {
                    hapticGenerator.impactOccurred(intensity: 0.5)
                    authViewModel.logout()
                    navigationState.navigateTo(.login)
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16))
                        Text("LOG OUT")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.GeneratedColors.error)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.GeneratedColors.error, lineWidth: 1.5)
                    )
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(red: 0.93, green: 0.91, blue: 0.86))
            .clipShape(RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight]))
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private func formField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.GeneratedColors.deepOps.opacity(0.8))
                .tracking(1)
            
            TextField(placeholder, text: text)
                .font(AppTheme.GeneratedTypography.body())
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.GeneratedColors.deepOps.opacity(0.2), lineWidth: 1)
                )
                .disabled(isSubmitting)
                .keyboardType(keyboardType)
                .autocapitalization(keyboardType == .emailAddress ? .none : .words)
        }
    }
    
    @ViewBuilder
    private func secureFormField(
        title: String,
        text: Binding<String>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.GeneratedColors.deepOps.opacity(0.8))
                .tracking(1)
            
            SecureField(placeholder, text: text)
                .font(AppTheme.GeneratedTypography.body())
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.GeneratedColors.deepOps.opacity(0.2), lineWidth: 1)
                )
                .disabled(isChangingPassword)
                .onChange(of: text.wrappedValue) { _, _ in
                    validatePasswords()
                }
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
                self.authViewModel.setMockUser(user)
            }
            
            // Auto-dismiss success message
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    self.showSuccessMessage = false
                    self.message = nil
                }
            }
        }
    }
    
    private func validatePasswords() {
        passwordsMatch = newPassword == confirmPassword
    }
    
    private func changePassword() {
        hapticGenerator.impactOccurred(intensity: 0.5)
        
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
                withAnimation {
                    self.showPasswordSuccessMessage = false
                    self.passwordMessage = nil
                }
            }
        }
    }
    
    private func formDataHasChanges() -> Bool {
        guard case .authenticated(let user) = authViewModel.authState else { return false }
        
        return (
            firstName != (user.firstName ?? "") ||
            lastName != (user.lastName ?? "") ||
            username != (user.username ?? "") ||
            email != (user.email ?? "")
        )
    }
    
    private func animateContentIn() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                headerVisible = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                sectionsVisible = true
            }
        }
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