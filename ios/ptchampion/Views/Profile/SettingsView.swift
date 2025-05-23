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
    
    // Animation states
    @State private var headerVisible = false
    @State private var sectionsVisible = [false, false, false, false]
    
    // App version
    private let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    
    // Web URLs
    private let privacyPolicyURL = URL(string: "https://ptchampion.ai/privacy.html")!
    private let termsOfServiceURL = URL(string: "https://ptchampion.ai/terms.html")!
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Ambient Background Gradient - matching Dashboard style
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
                        // Updated header matching other views
                        VStack(spacing: 16) {
                            HStack {
                                Text("SETTINGS")
                                    .font(.system(size: 32, weight: .bold))
                                    .tracking(2)
                                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                
                                Spacer()
                                
                                Button {
                                    hapticGenerator.impactOccurred(intensity: 0.3)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.left")
                                            .font(.system(size: 12))
                                        Text("BACK")
                                            .font(.system(size: 12, weight: .semibold))
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
                            
                            Text("CONFIGURE YOUR PREFERENCES")
                                .font(.system(size: 16, weight: .regular))
                                .tracking(1.5)
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                        .opacity(headerVisible ? 1 : 0)
                        .offset(y: headerVisible ? 0 : 10)
                        
                        // General Settings Section
                        generalSettingsSection
                            .opacity(sectionsVisible[0] ? 1 : 0)
                            .offset(y: sectionsVisible[0] ? 0 : 15)
                        
                        // Fitness Devices Section
                        fitnessDevicesSection
                            .opacity(sectionsVisible[1] ? 1 : 0)
                            .offset(y: sectionsVisible[1] ? 0 : 15)
                        
                        // Legal & About Section
                        legalAndAboutSection
                            .opacity(sectionsVisible[2] ? 1 : 0)
                            .offset(y: sectionsVisible[2] ? 0 : 15)
                        
                        // Danger Zone Section
                        dangerZoneSection
                            .opacity(sectionsVisible[3] ? 1 : 0)
                            .offset(y: sectionsVisible[3] ? 0 : 15)
                    }
                    .padding(AppTheme.GeneratedSpacing.contentPadding)
                }
            }
            .contentContainer()
            .navigationBarHidden(true)
            .onAppear {
                hapticGenerator.prepare()
                animateContentIn()
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
    
    // MARK: - General Settings Section
    private var generalSettingsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Dark header
            VStack(alignment: .leading, spacing: 4) {
                Text("GENERAL SETTINGS")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                    .padding(.bottom, 4)
                
                Text("CONFIGURE APPLICATION PREFERENCES")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.GeneratedColors.deepOps)
            .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))
            
            // Light content area
            VStack(spacing: 0) {
                // Geolocation Setting
                settingToggleRow(
                    icon: "location.fill",
                    title: "GEOLOCATION TRACKING",
                    description: "Allow location tracking for runs and local leaderboards",
                    isOn: $geolocationEnabled,
                    action: handleGeolocationToggle
                )
                
                Divider()
                    .background(AppTheme.GeneratedColors.deepOps.opacity(0.1))
                    .padding(.horizontal, AppTheme.GeneratedSpacing.medium)
                
                // Notifications Setting
                settingToggleRow(
                    icon: "bell.fill",
                    title: "NOTIFICATIONS",
                    description: "Receive reminders and updates about your workouts",
                    isOn: $notificationsEnabled,
                    action: handleNotificationsToggle
                )
            }
            .padding(.vertical, AppTheme.GeneratedSpacing.small)
            .background(Color(red: 0.93, green: 0.91, blue: 0.86))
            .clipShape(RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight]))
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Fitness Devices Section
    private var fitnessDevicesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Dark header
            VStack(alignment: .leading, spacing: 4) {
                Text("FITNESS DEVICES")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                    .padding(.bottom, 4)
                
                Text("CONNECT FITNESS TRACKING DEVICES")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.GeneratedColors.deepOps)
            .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))
            
            // Light content area
            VStack(spacing: 0) {
                Button {
                    hapticGenerator.impactOccurred(intensity: 0.5)
                    showingDeviceManagerSheet = true
                } label: {
                    HStack {
                        // Icon in circular container
                        ZStack {
                            Circle()
                                .fill(AppTheme.GeneratedColors.oliveMist.opacity(0.3))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("MANAGE DEVICES")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                            
                            Text("Connect watches and heart rate monitors")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color(red: 0.93, green: 0.91, blue: 0.86))
            .clipShape(RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight]))
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Legal & About Section
    private var legalAndAboutSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Dark header
            VStack(alignment: .leading, spacing: 4) {
                Text("ABOUT & LEGAL")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                    .padding(.bottom, 4)
                
                Text("APP INFORMATION AND LEGAL DOCUMENTS")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.GeneratedColors.deepOps)
            .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))
            
            // Light content area
            VStack(spacing: 0) {
                // App Version
                HStack {
                    ZStack {
                        Circle()
                            .fill(AppTheme.GeneratedColors.oliveMist.opacity(0.3))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    }
                    
                    Text("APP VERSION")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    
                    Spacer()
                    
                    Text(appVersion)
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                
                Divider()
                    .background(AppTheme.GeneratedColors.deepOps.opacity(0.1))
                    .padding(.horizontal, 20)
                
                // Terms of Service
                Button {
                    showTermsOfServiceSafari = true
                } label: {
                    HStack {
                        Text("TERMS OF SERVICE")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $showTermsOfServiceSafari) {
                    SafariView(url: termsOfServiceURL)
                        .edgesIgnoringSafeArea(.all)
                }
                
                Divider()
                    .background(AppTheme.GeneratedColors.deepOps.opacity(0.1))
                    .padding(.horizontal, 20)
                
                // Privacy Policy
                Button {
                    showPrivacyPolicySafari = true
                } label: {
                    HStack {
                        Text("PRIVACY POLICY")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $showPrivacyPolicySafari) {
                    SafariView(url: privacyPolicyURL)
                        .edgesIgnoringSafeArea(.all)
                }
                
                // Copyright Info
                Text("© \(String(Calendar.current.component(.year, from: Date()))) PT Champion. All rights reserved.")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
            }
            .background(Color(red: 0.93, green: 0.91, blue: 0.86))
            .clipShape(RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight]))
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Danger Zone Section
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Dark header with error color
            VStack(alignment: .leading, spacing: 4) {
                Text("DANGER ZONE")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.GeneratedColors.error)
                    .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.GeneratedColors.error.opacity(0.3))
                    .padding(.bottom, 4)
                
                Text("PERMANENTLY DELETE YOUR ACCOUNT")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.GeneratedColors.error)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.GeneratedColors.deepOps)
            .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))
            
            // Light content area
            VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                Text("Once you delete your account, there is no going back. All your data will be permanently removed.")
                    .font(AppTheme.GeneratedTypography.body())
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    .multilineTextAlignment(.leading)
                
                // Delete Account button
                Button {
                    showingDeleteConfirmation = true
                } label: {
                    HStack {
                        if isDeletingAccount {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                                .padding(.trailing, 8)
                        }
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                        Text(isDeletingAccount ? "DELETING..." : "DELETE ACCOUNT")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.GeneratedColors.error)
                    .cornerRadius(8)
                }
                .disabled(isDeletingAccount)
            }
            .padding()
            .background(Color(red: 0.93, green: 0.91, blue: 0.86))
            .clipShape(RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight]))
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private func settingToggleRow(
        icon: String,
        title: String,
        description: String,
        isOn: Binding<Bool>,
        action: @escaping (Bool) -> Void
    ) -> some View {
        HStack {
            // Icon in circular container
            ZStack {
                Circle()
                    .fill(AppTheme.GeneratedColors.oliveMist.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
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
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helper Methods
    private func handleGeolocationToggle(_ enabled: Bool) {
        if enabled {
            let locationManager = CLLocationManager()
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    private func handleNotificationsToggle(_ enabled: Bool) {
        if enabled {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
                // Handle result
            }
        }
    }
    
    private func animateContentIn() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                headerVisible = true
            }
        }
        
        for i in 0..<sectionsVisible.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + (Double(i) * 0.1)) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    sectionsVisible[i] = true
                }
            }
        }
    }
}

// Safari View Controller wrapper
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