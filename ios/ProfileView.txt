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
struct ScreenHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .center, spacing: AppTheme.GeneratedSpacing.small) {
            Text(title)
                .militaryMonospaced(size: AppTheme.GeneratedTypography.body)
                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.small))
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                .italic()
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppTheme.GeneratedSpacing.large)
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var fitnessDeviceManagerViewModel: FitnessDeviceManagerViewModel
    @Environment(\.colorScheme) var colorScheme 
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        ScreenContainer(
            title: "PROFILE",
            subtitle: "Personal settings & preferences"
        ) {
            // User Profile Header
            ProfileHeaderView(authViewModel: authViewModel, showingEditProfile: $showingEditProfile)
            
            // Quick Preferences Section
            ProfilePreferencesView(hapticGenerator: hapticGenerator)
            
            // Account Actions Section
            AccountActionsView()
            
            // More Options Section
            MoreActionsView()
                .environmentObject(fitnessDeviceManagerViewModel)
            
            // App Version Information
            AppInfoView()
        }
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
        .onAppear {
            hapticGenerator.prepare()
        }
    }
}

// Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView()
                .environmentObject(MockAuthViewModel())
                .environmentObject(FitnessDeviceManagerViewModel())
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