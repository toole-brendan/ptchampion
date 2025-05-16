import SwiftUI
import Foundation
import CoreLocation
import PTDesignSystem
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // Settings
    @AppStorage("geolocation") private var geolocationEnabled: Bool = false
    @AppStorage("notifications") private var notificationsEnabled: Bool = false
    
    // App version
    private let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    
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
                                            .militaryMonospaced(size: 14)
                                    }
                                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(AppTheme.GeneratedColors.brassGold, lineWidth: 1)
                                    )
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
                        
                        // Legal & About Section
                        legalAndAboutSection
                    }
                    .padding(AppTheme.GeneratedSpacing.contentPadding)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                hapticGenerator.prepare()
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
                            .militaryMonospaced(size: 18)
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    }
                    .padding(.bottom, 4)
                    
                    Text("Configure application preferences and permissions.")
                        .militaryMonospaced(size: 14)
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
                            .militaryMonospaced(size: 18)
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    }
                    .padding(.bottom, 4)
                    
                    Text("App information and legal documents.")
                        .militaryMonospaced(size: 14)
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    
                    // App Version
                    HStack {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                .font(.system(size: 16))
                            Text("App Version")
                                .militaryMonospaced(size: 16)
                                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        }
                        
                        Spacer()
                        
                        Text(appVersion)
                            .militaryMonospaced(size: 14)
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
                                .militaryMonospaced(size: 16)
                                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        }
                        
                        // Terms of Service
                        Button {
                            // Open Terms of Service
                        } label: {
                            Text("Terms of Service")
                                .militaryMonospaced(size: 14)
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                        }
                        .padding(.leading, 28)
                        
                        // Privacy Policy
                        Button {
                            // Open Privacy Policy
                        } label: {
                            Text("Privacy Policy")
                                .militaryMonospaced(size: 14)
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                        }
                        .padding(.leading, 28)
                    }
                    
                    // Copyright Info
                    Text("© \(Calendar.current.component(.year, from: Date())) PT Champion. All rights reserved.")
                        .militaryMonospaced(size: 12)
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
                            .militaryMonospaced(size: 16)
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    }
                    
                    Text(description)
                        .militaryMonospaced(size: 14)
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

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthViewModel())
    }
} 