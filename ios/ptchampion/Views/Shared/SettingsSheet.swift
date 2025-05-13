import SwiftUI
import PTDesignSystem

/*
 * DEPRECATION NOTICE
 * This component is deprecated and will be removed in a future update.
 * Please use SettingsView from the Views/Profile directory instead.
 * The ProfileView uses SettingsView for the settings modal.
 */

/// A reusable settings sheet component that can be presented modally
struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Configurable options
    var showAccountSettings: Bool = true
    var showAppearanceSettings: Bool = true
    var showNotificationSettings: Bool = true
    var showPrivacySettings: Bool = true
    var showAbout: Bool = true
    
    // State
    @State private var selectedDistanceUnit: DistanceUnit = .kilometers
    @State private var notificationsEnabled: Bool = true
    @State private var shareWorkouts: Bool = true
    @State private var darkModeEnabled: Bool = false
    @State private var showingLogoutConfirmation: Bool = false
    @State private var showingDeleteAccountConfirmation: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                // DEPRECATION NOTICE BANNER
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(ThemeColor.error)
                        Text("This component is deprecated. Please use SettingsView from the Profile directory instead.")
                            .caption()
                            .foregroundColor(ThemeColor.error)
                    }
                    .padding(.vertical, 8)
                }
                
                if showAccountSettings {
                    accountSection
                }
                
                if showAppearanceSettings {
                    appearanceSection
                }
                
                if showNotificationSettings {
                    notificationsSection
                }
                
                if showPrivacySettings {
                    privacySection
                }
                
                if showAbout {
                    aboutSection
                }
                
                // Logout button at the bottom
                Section {
                    Button(action: {
                        showingLogoutConfirmation = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .font(Font.system(.body, design: .default).bold())
                                .foregroundColor(ThemeColor.error)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Sign Out", isPresented: $showingLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authViewModel.logout()
                }
            } message: {
                Text("Are you sure you want to sign out of your account?")
            }
            .alert("Delete Account", isPresented: $showingDeleteAccountConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    // Handle account deletion
                }
            } message: {
                Text("This will permanently delete your account and all associated data. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Sections
    
    private var accountSection: some View {
        Section(header: Text("Account")) {
            if case .authenticated(let user) = authViewModel.authState {
                HStack {
                    VStack(alignment: .leading) {
                        Text([user.firstName, user.lastName].compactMap { $0 }.joined(separator: " ").ifEmpty(use: user.email))
                            .font(Font.system(.body, design: .default).bold())
                        Text(user.email)
                            .font(.system(size: Spacing.small))
                            .foregroundColor(ThemeColor.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(ThemeColor.brassGold)
                }
                .padding(.vertical, Spacing.small)
                
                Button(action: {
                    // Navigate to profile edit
                }) {
                    Text("Edit Profile")
                }
                
                Button(action: {
                    showingDeleteAccountConfirmation = true
                }) {
                    Text("Delete Account")
                        .foregroundColor(ThemeColor.error)
                }
            } else {
                Button(action: {
                    // Handle login/signup
                }) {
                    Text("Sign In or Create Account")
                }
            }
        }
    }
    
    private var appearanceSection: some View {
        Section(header: Text("Appearance")) {
            Picker("Distance Units", selection: $selectedDistanceUnit) {
                ForEach(DistanceUnit.allCases, id: \.self) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
            
            Toggle("Dark Mode", isOn: $darkModeEnabled)
                .onChange(of: darkModeEnabled) {
                    // Apply theme change
                }
        }
    }
    
    private var notificationsSection: some View {
        Section(header: Text("Notifications")) {
            Toggle("Enable Notifications", isOn: $notificationsEnabled)
            
            if notificationsEnabled {
                NavigationLink("Configure Notifications") {
                    notificationPreferencesView
                }
            }
        }
    }
    
    private var privacySection: some View {
        Section(header: Text("Privacy")) {
            Toggle("Share Workouts to Leaderboard", isOn: $shareWorkouts)
            
            NavigationLink("Privacy Policy") {
                WebViewWrapper(url: URL(string: "https://ptchampion.com/privacy")!)
                    .navigationTitle("Privacy Policy")
            }
            
            NavigationLink("Terms of Service") {
                WebViewWrapper(url: URL(string: "https://ptchampion.com/terms")!)
                    .navigationTitle("Terms of Service")
            }
        }
    }
    
    private var aboutSection: some View {
        Section(header: Text("About")) {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.appVersionAndBuild)
                    .foregroundColor(ThemeColor.textSecondary)
            }
            
            NavigationLink("Send Feedback") {
                feedbackView
            }
            
            Button(action: {
                guard let url = URL(string: "https://ptchampion.com/help"),
                      UIApplication.shared.canOpenURL(url) else {
                    return
                }
                UIApplication.shared.open(url)
            }) {
                Text("Help Center")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var notificationPreferencesView: some View {
        List {
            Toggle("Workout Reminders", isOn: .constant(true))
            Toggle("Achievements", isOn: .constant(true))
            Toggle("Leaderboard Updates", isOn: .constant(false))
        }
        .navigationTitle("Notifications")
    }
    
    private var feedbackView: some View {
        VStack {
            TextEditor(text: .constant(""))
                .frame(minHeight: 200)
                .padding()
                .background(SwiftUI.Color.gray.opacity(0.5))
                .cornerRadius(CornerRadius.medium)
                .padding()
            
            // Use a typed local variable to resolve ambiguity
            let coreButtonStyle: PTButton.ButtonStyle = .primary
            PTButton("Submit Feedback", style: coreButtonStyle) {
                // Submit feedback
                dismiss()
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationTitle("Feedback")
    }
}

// MARK: - WebView Wrapper

struct WebViewWrapper: View {
    let url: URL
    
    var body: some View {
        // This would be replaced with a real WebView implementation
        // For now, just showing a placeholder since WebKit import might not be available
        VStack {
            Text("Loading \(url.absoluteString)...")
                .padding()
            
            Spacer()
        }
    }
}

// MARK: - Bundle Extension for Version

extension Bundle {
    var appVersionAndBuild: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Preview

struct SettingsSheet_Previews: PreviewProvider {
    static var previews: some View {
        // Use the MockAuthViewModel (assuming it's accessible, e.g., defined globally or in ProfileView.swift)
        let mockAuth = MockAuthViewModel()
        
        // To set a user for preview, we modify the authState directly if the MockAuthViewModel allows
        // Or, if MockAuthViewModel has a specific method to set a mock user, use that.
        // Based on AuthViewModel, we set the state to .authenticated with an AuthUserModel
        let previewUser = AuthUserModel(
            id: "previewUser123",
            email: "preview@example.com",
            firstName: "Preview",
            lastName: "User",
            profilePictureUrl: nil // Assuming AuthUserModel has this property
        )
        // mockAuth.authState = .authenticated(previewUser) // This is inaccessible
        mockAuth.setMockUser(previewUser) // Use the provided setter method
        
        return SettingsSheet()
            .environmentObject(mockAuth)
    }
}

// MARK: - String Extension for Empty Check

extension String {
    /// Returns `self` unless it's empty, in which case `fallback` is returned.
    func ifEmpty(use fallback: @autoclosure () -> String) -> String {
        isEmpty ? fallback() : self
    }
} 