import SwiftUI
import PTDesignSystem

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme // To react to system changes
    @Environment(\.scenePhase) var scenePhase // To apply theme on scene activation

    @State private var showingEditProfile = false
    
    // Enum for appearance settings
    enum AppearanceSetting: String, CaseIterable, Identifiable {
        case light = "Light"
        case dark = "Dark" // Added Dark mode
        case system = "System"
        var id: String { self.rawValue }
    }
    // Persist selected appearance using AppStorage
    @AppStorage("selectedAppearance") private var selectedAppearance: AppearanceSetting = .system

    // Enum for unit settings
    enum UnitSetting: String, CaseIterable, Identifiable {
        case metric = "Metric (kg, km)"
        case imperial = "Imperial (lbs, miles)"
        var id: String { self.rawValue }
    }
    @AppStorage("selectedUnit") private var selectedUnit: UnitSetting = .metric
    
    @AppStorage("workoutRemindersEnabled") private var workoutRemindersEnabled: Bool = true
    @AppStorage("achievementNotificationsEnabled") private var achievementNotificationsEnabled: Bool = true

    @State private var showingChangePassword = false
    @State private var showingPrivacyPolicy = false
    @State private var showingConnectedDevices = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        // The NavigationStack is provided by ContentView for this tab
        Form {
            // Section 1: Profile Information
            Section {
                HStack(spacing: 15) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary) // Keep or use theme accent
                    
                    VStack(alignment: .leading) {
                        PTLabel(authViewModel.displayName ?? "N/A", style: .heading) // .heading uses textPrimary
                        PTLabel(authViewModel.email ?? "N/A", style: .body) // .body uses textSecondary
                    }
                }
                Button("Edit Profile") { // Standard Form button
                    showingEditProfile = true
                }
            } header: {
                PTLabel("Profile Information", style: .subheading)
                    .padding(.top)
            }

            // Section 2: Settings
            Section {
                Picker(selection: $selectedAppearance) {
                    ForEach(AppearanceSetting.allCases) { appearance in
                        Text(appearance.rawValue).tag(appearance)
                    }
                } label: {
                    PTLabel("Appearance", style: .body) // .body uses textSecondary
                }
                .onChange(of: selectedAppearance) { newAppearance in
                    applyAppearance(newAppearance)
                }
                
                Picker(selection: $selectedUnit) {
                    ForEach(UnitSetting.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                } label: {
                    PTLabel("Units", style: .body)
                }

                // Toggle constructed with HStack for custom label styling
                HStack {
                    PTLabel("Workout Reminders", style: .body) // PTLabel should now control its color
                    Spacer()
                    Toggle("", isOn: $workoutRemindersEnabled)
                        .labelsHidden()
                }
                // Original Toggle for New Achievements (for comparison)
                Toggle(isOn: $achievementNotificationsEnabled) {
                    PTLabel("New Achievements", style: .body)
                }
            } header: {
                PTLabel("Settings", style: .subheading)
                    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    .padding(.top)
            }
            
            // Section 3: Account Management
            Section {
                // Logout Button constructed with HStack for custom label styling
                HStack {
                    PTLabel("Logout", style: .body)
                        .foregroundColor(AppTheme.GeneratedColors.error)
                    Spacer()
                }
                .contentShape(Rectangle()) // Make the whole HStack tappable
                .onTapGesture {
                    authViewModel.logout()
                }
                
                Button {
                    showingChangePassword = true
                } label: {
                    PTLabel("Change Password", style: .body)
                        // Default .body color is textSecondary, let's make it interactable
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary) 
                }
                
                Button {
                    showingDeleteConfirmation = true
                } label: {
                    PTLabel("Delete Account", style: .body)
                        .foregroundColor(AppTheme.GeneratedColors.error)
                }
            } header: {
                PTLabel("Account", style: .subheading)
                    .padding(.top)
            }
            
            // Section 4: More
            Section {
                Button {
                    showingPrivacyPolicy = true
                } label: {
                    PTLabel("Privacy Policy", style: .body)
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                }
                Button {
                    showingConnectedDevices = true
                } label: {
                    PTLabel("Connected Devices", style: .body)
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                }
                PTLabel("App Version: \(appVersion())", style: .caption) // .caption uses textTertiary
            } header: {
                PTLabel("More", style: .subheading)
                    .padding(.top)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline) // Or .large, as preferred
        .sheet(isPresented: $showingEditProfile) {
            // Placeholder for EditProfileView
            // For a real EditProfileView, wrap it in a NavigationView for its own toolbar
            NavigationView {
                Text("Edit Profile View (TODO)")
                    .navigationTitle("Edit Profile")
                    .navigationBarItems(leading: Button("Cancel") { showingEditProfile = false }, 
                                        trailing: Button("Save") { /* TODO: Save action */ showingEditProfile = false })
            }
        }
        .sheet(isPresented: $showingChangePassword) {
            NavigationView {
                Text("Change Password View (TODO)")
                    .navigationTitle("Change Password")
                    .navigationBarItems(leading: Button("Cancel") { showingChangePassword = false },
                                        trailing: Button("Save") { /* TODO: Save action */ showingChangePassword = false })
            }
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            NavigationView {
                Text("Privacy Policy View (TODO)")
                    .navigationTitle("Privacy Policy")
                    .navigationBarItems(trailing: Button("Done") { showingPrivacyPolicy = false })
            }
        }
        .sheet(isPresented: $showingConnectedDevices) {
            NavigationView {
                Text("Connected Devices View (TODO)")
                    .navigationTitle("Connected Devices")
                    .navigationBarItems(trailing: Button("Done") { showingConnectedDevices = false })
            }
        }
        .alert("Confirm Delete", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                // TODO: Implement account deletion logic
                // authViewModel.deleteAccount()
                // For now, just dismiss
                showingDeleteConfirmation = false
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .onAppear {
            applyAppearance(selectedAppearance) // Apply on view appear
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                applyAppearance(selectedAppearance) // Re-apply if app becomes active (e.g. system theme changed)
            }
        }
    }
    
    private func appVersion() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
    }

    private func applyAppearance(_ appearance: AppearanceSetting) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        windowScene.windows.forEach { window in
            switch appearance {
            case .light:
                window.overrideUserInterfaceStyle = .light
            case .dark:
                window.overrideUserInterfaceStyle = .dark
            case .system:
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
    }
}

// Mock AuthViewModel for Previews - Ensure this matches your actual AuthViewModel structure if it exists
// If AuthViewModel is complex, consider a more robust mocking strategy or using a simplified protocol.
class MockAuthViewModel: AuthViewModel {
    // Override properties and methods as needed for previews
    // For this example, we assume base AuthViewModel can be instantiated
    // and we can set some properties for preview display if needed.
    // If your AuthViewModel() initializer is complex or has dependencies,
    // this mock will need to be adjusted.
    
    override init() {
        super.init() // Call the designated initializer of the superclass
        // Create a mock user
        let mockUser = AuthUserModel(
            id: "mockUserID123",
            email: "user@example.com",
            firstName: "Preview", // This will be used by the `displayName` computed property
            lastName: "User",
            profilePictureUrl: nil // Assuming AuthUserModel has this
        )
        // Set the mock user using the method from AuthViewModel
        // This will internally set the authState to .authenticated(mockUser)
        self.setMockUser(mockUser)
        
        // After setMockUser, authState will be .authenticated(mockUser),
        // so computed properties like displayName and email (now added) will work.
        // No need to set self.displayName or self.email directly.
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { // Use NavigationStack for previews if the view uses navigation features
            ProfileView()
                .environmentObject(MockAuthViewModel()) // Provide the mock for the preview
        }
    }
} 