import SwiftUI
import Foundation
import CoreLocation
import PTDesignSystem
import UserNotifications
import SafariServices

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var navigationState: NavigationState
    @EnvironmentObject private var fitnessDeviceManagerViewModel: FitnessDeviceManagerViewModel
    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    @State private var showPrivacyPolicySafari = false
    @State private var showTermsOfServiceSafari = false
    @State private var showingDeviceManagerSheet = false
    @State private var isDeletingAccount = false
    @State private var showingDeleteConfirmation = false
    
    // Settings
    @AppStorage("geolocation") private var geolocationEnabled: Bool = false
    @AppStorage("notifications") private var notificationsEnabled: Bool = false
    
    // App version
    private let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    
    // Web URLs
    private let privacyPolicyURL = URL(string: "https://ptchampion.ai/privacy.html")!
    private let termsOfServiceURL = URL(string: "https://ptchampion.ai/terms.html")!
    
    var body: some View {
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
                        // Page Header
                        VStack(spacing: 16) {
                            HStack {
                                Text("Settings")
                                    .font(.system(size: 32, weight: .bold))
                                    .tracking(2)
                                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                
                                Spacer()
                                
                                Button {
                                    hapticGenerator.impactOccurred(intensity: 0.3)
                                    dismiss()
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.left")
                                            .font(.system(size: 14))
                                        Text("BACK TO PROFILE")
                                            .font(AppTheme.GeneratedTypography.bodyBold(size: 14))
                                    }
                                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(AppTheme.GeneratedColors.deepOps)
                                    .cornerRadius(6)
                                }
                            }
                            
                            Rectangle()
                                .frame(width: 120, height: 1.5)
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.bottom, AppTheme.GeneratedSpacing.small)
                        
                        // General Settings Section
                        generalSettingsSection
                        
                        // Fitness Devices Section
                        fitnessDevicesSection
                        
                        // Legal & About Section
                        legalAndAboutSection
                        
                        // Danger Zone Section (moved from ProfileView)
                        dangerZoneSection
                    }
                    .padding(AppTheme.GeneratedSpacing.contentPadding)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                hapticGenerator.prepare()
            }
            .sheet(isPresented: $showingDeviceManagerSheet) {
                NavigationView {
                    FitnessDeviceManagerView()
                        .environmentObject(fitnessDeviceManagerViewModel)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") { showingDeviceManagerSheet = false }
                            }
                        }
                }
            }
            .alert("Confirm Delete", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    isDeletingAccount = true
                    // In a real app, this would call the delete account API
                    // Then log the user out
                    authViewModel.logout()
                    dismiss()
                    navigationState.navigateTo(.login)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Danger Zone Section
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
            PTCard(style: .standard) {
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(AppTheme.GeneratedColors.error)
                            .font(.system(size: 20))
                        Text("Danger Zone")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(AppTheme.GeneratedColors.error)
                    }
                    .padding(.bottom, 4)
                    
                    Text("Permanently delete your account and all data.")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    
                    // Delete Account button
                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            if isDeletingAccount {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                            }
                            Text(isDeletingAccount ? "Deleting..." : "Delete Account")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.GeneratedColors.error)
                        .cornerRadius(8)
                    }
                    .disabled(isDeletingAccount)
                }
                .padding()
            }
        }
    }
    
    // MARK: - General Settings Section
    private var generalSettingsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
            PTCard(style: .standard) {
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                            .font(.system(size: 20))
                        Text("General Settings")
                            .font(AppTheme.GeneratedTypography.heading(size: 18))
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    }
                    .padding(.bottom, 4)
                    
                    Text("Configure application preferences and permissions.")
                        .font(AppTheme.GeneratedTypography.body(size: 14))
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    
                    // Geolocation Setting
                    settingToggle(
                        icon: "location.fill", 
                        title: "Geolocation Tracking", 
                        description: "Allow location tracking for runs and local leaderboards.",
                        isOn: $geolocationEnabled,
                        action: handleGeolocationToggle
                    )
                    
                    Divider().padding(.vertical, 8)
                    
                    // Notifications Setting
                    settingToggle(
                        icon: "bell.fill", 
                        title: "Notifications", 
                        description: "Receive reminders and updates about your workouts.",
                        isOn: $notificationsEnabled,
                        action: handleNotificationsToggle
                    )
                }
                .padding()
            }
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Fitness Devices Section
    private var fitnessDevicesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
            PTCard(style: .standard) {
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                            .font(.system(size: 20))
                        Text("Fitness Devices")
                            .font(AppTheme.GeneratedTypography.heading(size: 18))
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    }
                    .padding(.bottom, 4)
                    
                    Text("Connect or manage fitness tracking devices like watches or heart rate monitors.")
                        .font(AppTheme.GeneratedTypography.body(size: 14))
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    
                    Button {
                        hapticGenerator.impactOccurred(intensity: 0.5)
                        showingDeviceManagerSheet = true
                    } label: {
                        HStack {
                            Label("Fitness Devices", systemImage: "antenna.radiowaves.left.and.right")
                                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .frame(height: 44)
                    .padding()
                    .background(AppTheme.GeneratedColors.background.opacity(0.5))
                    .cornerRadius(8)
                }
                .padding()
            }
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Legal & About Section
    private var legalAndAboutSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
            PTCard(style: .standard) {
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                            .font(.system(size: 20))
                        Text("About & Legal")
                            .font(AppTheme.GeneratedTypography.heading(size: 18))
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    }
                    .padding(.bottom, 4)
                    
                    Text("App information and legal documents.")
                        .font(AppTheme.GeneratedTypography.body(size: 14))
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    
                    // App Version
                    HStack {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                .font(.system(size: 16))
                            Text("App Version")
                                .font(AppTheme.GeneratedTypography.bodyBold(size: 16))
                                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        }
                        
                        Spacer()
                        
                        Text(appVersion)
                            .font(AppTheme.GeneratedTypography.body(size: 14))
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    }
                    .padding(.vertical, 8)
                    
                    Divider().padding(.vertical, 4)
                    
                    // Legal Documents
                    VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                        HStack {
                            Image(systemName: "shield.fill")
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                .font(.system(size: 16))
                            Text("Legal Documents")
                                .font(AppTheme.GeneratedTypography.bodyBold(size: 16))
                                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        }
                        
                        // Terms of Service
                        Button {
                            // Open Terms of Service
                            showTermsOfServiceSafari = true
                        } label: {
                            Text("Terms of Service")
                                .font(AppTheme.GeneratedTypography.bodyBold(size: 14))
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                        }
                        .padding(.leading, 28)
                        .sheet(isPresented: $showTermsOfServiceSafari) {
                            SafariView(url: termsOfServiceURL)
                                .edgesIgnoringSafeArea(.all)
                        }
                        
                        // Privacy Policy
                        Button {
                            // Open Privacy Policy
                            showPrivacyPolicySafari = true
                        } label: {
                            Text("Privacy Policy")
                                .font(AppTheme.GeneratedTypography.bodyBold(size: 14))
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                        }
                        .padding(.leading, 28)
                        .sheet(isPresented: $showPrivacyPolicySafari) {
                            SafariView(url: privacyPolicyURL)
                                .edgesIgnoringSafeArea(.all)
                        }
                    }
                    
                    // Copyright Info
                    Text("© \(String(Calendar.current.component(.year, from: Date()))) PT Champion. All rights reserved.")
                        .font(AppTheme.GeneratedTypography.body(size: 12))
                        .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 16)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private func settingToggle(
        icon: String,
        title: String,
        description: String,
        isOn: Binding<Bool>,
        action: @escaping (Bool) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: icon)
                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                            .font(.system(size: 16))
                        
                        Text(title)
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    }
                    
                    Text(description)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 24)
                }
                
                Spacer()
                
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(AppTheme.GeneratedColors.brassGold)
                    .onChange(of: isOn.wrappedValue) { _, newValue in
                        hapticGenerator.impactOccurred(intensity: 0.4)
                        action(newValue)
                    }
            }
        }
        .padding()
        .background(AppTheme.GeneratedColors.background.opacity(0.5))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    private func handleGeolocationToggle(_ enabled: Bool) {
        if enabled {
            // Request location permissions
            let locationManager = CLLocationManager()
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    private func handleNotificationsToggle(_ enabled: Bool) {
        if enabled {
            // Request notification permissions
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
                // Handle result
            }
        }
    }
}

// Add Safari View Controller wrapper
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
        // No updates needed
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthViewModel())
            .environmentObject(NavigationState())
            .environmentObject(FitnessDeviceManagerViewModel())
    }
} 