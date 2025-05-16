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
                    .militaryMonospaced(size: AppTheme.GeneratedTypography.body)
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
    @EnvironmentObject var fitnessDeviceManagerViewModel: FitnessDeviceManagerViewModel
    @Environment(\.colorScheme) var colorScheme 
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .medium)

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
                                
                                Button {
                                    hapticGenerator.impactOccurred(intensity: 0.3)
                                    showingSettings = true
                                } label: {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Rectangle()
                                .frame(width: 120, height: 1.5)
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("PERSONAL SETTINGS & PREFERENCES")
                                .font(.system(size: 16, weight: .regular))
                                .tracking(1.5)
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
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
                    .padding(AppTheme.GeneratedSpacing.contentPadding)
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