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

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme 
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dynamicTypeSize) var dynamicTypeSize // Added for accessibility
    
    @State private var showingEditProfile = false
    @State private var showingSettings = false // Add state for settings sheet
    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // Enum for appearance settings
    enum AppearanceSetting: String, CaseIterable, Identifiable {
        case light = "Light"
        case dark = "Dark"
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
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.GeneratedSpacing.large) {
                    // Custom header to match Leaderboard style exactly
                    VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                        Text("PROFILE")
                            .militaryMonospaced(size: AppTheme.GeneratedTypography.body)
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        
                        Text("Personal settings & preferences")
                            .font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.small))
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                            .italic()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppTheme.GeneratedSpacing.contentPadding)
                    
                    // Modernized Profile Info Card
                    profileInfoCard()
                    
                    // Settings Sections using cards
                    settingsSection()
                    
                    // Account Section
                    accountSection()
                    
                    // More Section
                    moreSection()
                    
                    // Footer with app version
                    Text("App Version: \(appVersion())")
                        .font(.footnote)
                        .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, AppTheme.GeneratedSpacing.medium)
                }
                .padding([.horizontal, .bottom], AppTheme.GeneratedSpacing.contentPadding)
            }
            .background(AppTheme.GeneratedColors.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        hapticGenerator.impactOccurred(intensity: 0.3)
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                NavigationView {
                    EditProfileView()
                        .environmentObject(authViewModel)
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationView {
                    SettingsView()
                        .environmentObject(authViewModel)
                }
            }
            .sheet(isPresented: $showingChangePassword) {
                NavigationView {
                    Text("Change Password View (TODO)")
                        .navigationTitle("Change Password")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Cancel") { 
                                    showingChangePassword = false 
                                }
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Save") { 
                                    showingChangePassword = false 
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                NavigationView {
                    Text("Privacy Policy View (TODO)")
                        .navigationTitle("Privacy Policy")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") { 
                                    showingPrivacyPolicy = false 
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingConnectedDevices) {
                NavigationView {
                    Text("Connected Devices View (TODO)")
                        .navigationTitle("Connected Devices")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") { 
                                    showingConnectedDevices = false 
                                }
                            }
                        }
                }
            }
            .alert("Confirm Delete", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    showingDeleteConfirmation = false
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone.")
            }
            .onAppear {
                applyAppearance(selectedAppearance)
                hapticGenerator.prepare() // Prepare haptic generator when view appears
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    applyAppearance(selectedAppearance)
                }
            }
        }
    }
    
    // MARK: - Profile Info Card
    @ViewBuilder
    private func profileInfoCard() -> some View {
        VStack(spacing: AppTheme.GeneratedSpacing.medium) {
            // Avatar image or placeholder
            ZStack {
                Circle()
                    .fill(AppTheme.GeneratedColors.primary.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(AppTheme.GeneratedColors.primary)
                    .frame(width: 80, height: 80)
            }
            .padding(.top, AppTheme.GeneratedSpacing.medium)
            
            // User information
            VStack(spacing: AppTheme.GeneratedSpacing.small) {
                Text(authViewModel.displayName ?? "N/A")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                
                Text(authViewModel.email ?? "N/A")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
            }
            
            // Edit profile button
            Button {
                hapticGenerator.impactOccurred(intensity: 0.5)
                showingEditProfile = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .font(.footnote)
                    Text("Edit Profile")
                        .font(.footnote.weight(.medium))
                }
                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .stroke(AppTheme.GeneratedColors.brassGold, lineWidth: 1)
                )
            }
            .padding(.bottom, AppTheme.GeneratedSpacing.small)
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.GeneratedColors.cardBackground)
        .cornerRadius(AppTheme.GeneratedRadius.card)
        .profileShadow(size: .small)
    }
    
    // MARK: - Settings Section
    @ViewBuilder
    private func settingsSection() -> some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
            // Section Header
            sectionHeader("Settings")
            
            // Appearance & Units Card
            settingsCard {
                // Appearance Picker
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                    HStack {
                        Label("Appearance", systemImage: "paintbrush.fill")
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        
                        Spacer()
                        
                        Picker("", selection: $selectedAppearance) {
                            ForEach(AppearanceSetting.allCases) { appearance in
                                Text(appearance.rawValue).tag(appearance)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 120)
                    }
                    .frame(height: 44) // Ensure touch target size
                    
                    // Dark mode notice
                    Text("Dark mode support is in progress.")
                        .font(.caption)
                        .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                        .italic()
                        .padding(.leading, 28) // Align with text after icon
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Units Picker
                HStack {
                    Label("Units", systemImage: "ruler")
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    
                    Spacer()
                    
                    Picker("", selection: $selectedUnit) {
                        ForEach(UnitSetting.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 200)
                }
                .frame(height: 44)
            }
            
            // Notifications Card
            settingsCard {
                // Workout Reminders Toggle
                HStack {
                    Label("Workout Reminders", systemImage: "bell.fill")
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $workoutRemindersEnabled)
                        .tint(AppTheme.GeneratedColors.brassGold)
                        .onChange(of: workoutRemindersEnabled) { _ in
                            hapticGenerator.impactOccurred(intensity: 0.4)
                        }
                }
                .frame(height: 44)
                
                Divider()
                    .padding(.vertical, 8)
                
                // New Achievements Toggle
                HStack {
                    Label("New Achievements", systemImage: "trophy.fill")
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $achievementNotificationsEnabled)
                        .tint(AppTheme.GeneratedColors.brassGold)
                        .onChange(of: achievementNotificationsEnabled) { _ in
                            hapticGenerator.impactOccurred(intensity: 0.4)
                        }
                }
                .frame(height: 44)
            }
        }
    }
    
    // MARK: - Account Section
    @ViewBuilder
    private func accountSection() -> some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
            // Section Header
            sectionHeader("Account")
            
            // Account Card
            settingsCard {
                // Change Password
                Button {
                    hapticGenerator.impactOccurred(intensity: 0.5)
                    showingChangePassword = true
                } label: {
                    HStack {
                        Label("Change Password", systemImage: "lock.fill")
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                    }
                    .contentShape(Rectangle())
                }
                .frame(height: 44)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Logout Button
                Button {
                    hapticGenerator.impactOccurred(intensity: 0.6)
                    authViewModel.logout()
                } label: {
                    HStack {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(AppTheme.GeneratedColors.error)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .frame(height: 44)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Delete Account
                Button {
                    hapticGenerator.impactOccurred(intensity: 0.7)
                    showingDeleteConfirmation = true
                } label: {
                    HStack {
                        Label("Delete Account", systemImage: "trash.fill")
                            .foregroundColor(AppTheme.GeneratedColors.error)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .frame(height: 44)
            }
        }
    }
    
    // MARK: - More Section
    @ViewBuilder
    private func moreSection() -> some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
            // Section Header
            sectionHeader("More")
            
            // More Card
            settingsCard {
                // Privacy Policy
                Button {
                    hapticGenerator.impactOccurred(intensity: 0.5)
                    showingPrivacyPolicy = true
                } label: {
                    HStack {
                        Label("Privacy Policy", systemImage: "doc.text.fill")
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                    }
                    .contentShape(Rectangle())
                }
                .frame(height: 44)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Connected Devices
                Button {
                    hapticGenerator.impactOccurred(intensity: 0.5)
                    showingConnectedDevices = true
                } label: {
                    HStack {
                        Label("Connected Devices", systemImage: "antenna.radiowaves.left.and.right")
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                    }
                    .contentShape(Rectangle())
                }
                .frame(height: 44)
            }
        }
    }
    
    // MARK: - Helper Views
    
    // Section Header
    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
    
    // Card Container for Settings
    @ViewBuilder
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(AppTheme.GeneratedSpacing.contentPadding)
        .background(AppTheme.GeneratedColors.cardBackground)
        .cornerRadius(AppTheme.GeneratedRadius.card)
        .profileShadow(size: .small)
    }
    
    // MARK: - Helper Methods
    
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