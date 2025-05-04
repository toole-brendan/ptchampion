import SwiftUI
import PTDesignSystem

/// A comprehensive showcase of all UI components used in the app
/// Helps maintain design consistency and provides a quick way to test component appearance
struct ComponentGalleryView: View {
    @State private var selectedComponent = 0
    @State private var textFieldValue = ""
    @State private var passwordValue = "password123"
    @State private var showingSettingsSheet = false
    
    // Components to display
    private let components = [
        "Buttons",
        "TextFields",
        "MetricCards",
        "WorkoutCards",
        "Badges",
        "Toasts",
        "Spinners",
        "Headers",
        "Lists",
        "Sheets",
        "Typography",
        "Colors"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Component selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.GeneratedSpacing.medium) {
                        ForEach(0..<components.count, id: \.self) { index in
                            Button(action: {
                                withAnimation {
                                    selectedComponent = index
                                }
                            }) {
                                PTLabel(components[index], style: .bodyBold)
                                    .foregroundColor(selectedComponent == index ? AppTheme.GeneratedColors.primary : AppTheme.GeneratedColors.textSecondary)
                                    .padding(.vertical, AppTheme.GeneratedSpacing.small)
                                    .padding(.horizontal, AppTheme.GeneratedSpacing.medium)
                                    .background(selectedComponent == index ? AppTheme.GeneratedColors.primaryLight : Color.clear)
                                    .cornerRadius(AppTheme.GeneratedRadius.full)
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.GeneratedSpacing.medium)
                }
                .padding(.vertical, AppTheme.GeneratedSpacing.small)
                .background(AppTheme.GeneratedColors.cardBackground)
                
                PTSeparator()
                
                // Component content
                ScrollView {
                    VStack(spacing: AppTheme.GeneratedSpacing.large) {
                        switch selectedComponent {
                        case 0:
                            buttonsSection
                        case 1:
                            textFieldsSection
                        case 2:
                            metricCardsSection
                        case 3:
                            workoutCardsSection
                        case 4:
                            badgesSection
                        case 5:
                            toastsSection
                        case 6:
                            spinnersSection
                        case 7:
                            headersSection
                        case 8:
                            listsSection
                        case 9:
                            sheetsSection
                        case 10:
                            typographySection
                        case 11:
                            colorsSection
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
                .background(AppTheme.GeneratedColors.background.opacity(0.5))
            }
            .navigationTitle("Component Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSettingsSheet) {
                // Display settings sheet when triggered
                let mockAuth = AuthViewModel()
                mockAuth.currentUser = User(id: "preview", email: "user@example.com", displayName: "Preview User")
                
                SettingsSheet()
                    .environmentObject(mockAuth)
            }
        }
    }
    
    // MARK: - Component Sections
    
    private var buttonsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.large) {
            sectionHeader(title: "Buttons", description: "Button components with different variants")
            
            VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                PTButton("Primary Button") {}
                
                PTButton("Secondary Button", style: .secondary) {
                    // action
                }
                
                PTButton("Outline Button", style: .outline) {
                    // action
                }
                
                PTButton("Ghost Button", style: .ghost) {
                    // action
                }
                
                PTButton("Destructive Button", style: .destructive) {
                    // action
                }
                
                // Since PTButton might not have loading state built in yet, 
                // you may need to create your own loading button or extend PTButton
                
                PTSeparator().padding(.vertical, AppTheme.GeneratedSpacing.small)
                
                HStack(spacing: AppTheme.GeneratedSpacing.medium) {
                    PTButton("Small", size: .small) {
                        // action
                    }
                    
                    PTButton("Medium", size: .medium) {
                        // action
                    }
                    
                    PTButton("Large", size: .large) {
                        // action
                    }
                }
            }
        }
    }
    
    private var textFieldsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.large) {
            sectionHeader(title: "Text Fields", description: "Text input components with different states")
            
            VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                // Empty state
                PTTextField(
                    "Enter username",
                    text: $textFieldValue,
                    label: "Username"
                )
                
                // With icon
                PTTextField(
                    "Enter username",
                    text: .constant("johndoe"),
                    label: "Username",
                    icon: Image(systemName: "person")
                )
                .validationState(.valid)
                
                // Error state
                PTTextField(
                    "Enter username",
                    text: .constant("j"),
                    label: "Username"
                )
                .validationState(.invalid(message: "Username must be at least 3 characters"))
                
                // Password field
                PTTextField(
                    "Enter password",
                    text: $passwordValue,
                    label: "Password",
                    isSecure: true,
                    icon: Image(systemName: "lock")
                )
                
                // Email with keyboard type
                PTTextField(
                    "Enter email",
                    text: .constant("user@example.com"),
                    label: "Email Address",
                    icon: Image(systemName: "envelope"),
                    keyboardType: .emailAddress
                )
            }
        }
    }
    
    private var metricCardsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.large) {
            sectionHeader(title: "Metric Cards", description: "Cards displaying key metrics and stats")
            
            VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                HStack(spacing: AppTheme.GeneratedSpacing.medium) {
                    MetricCard(
                        .init(
                            title: "TOTAL WORKOUTS",
                            value: 42,
                            icon: Image(systemName: "flame.fill")
                        )
                    )
                    .frame(maxWidth: .infinity)
                    
                    MetricCard(
                        .init(
                            title: "DISTANCE", 
                            value: 8.5, 
                            unit: "km",
                            icon: Image(systemName: "figure.run")
                        )
                    )
                    .frame(maxWidth: .infinity)
                }
                
                MetricCard(
                    .init(
                        title: "LAST ACTIVITY",
                        value: "Pull-ups",
                        description: "Yesterday - 42 reps",
                        icon: Image(systemName: "clock")
                    )
                )
            }
        }
    }
    
    private var workoutCardsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.large) {
            sectionHeader(title: "Workout Cards", description: "Cards displaying workout details")
            
            VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                WorkoutCard(
                    title: "Push-ups Workout",
                    subtitle: "Morning Routine",
                    date: Date(),
                    metrics: [
                        WorkoutMetric(title: "Reps", value: 42, iconSystemName: "flame.fill"),
                        WorkoutMetric(title: "Time", value: "2:30", unit: "min", iconSystemName: "clock")
                    ]
                )
                
                WorkoutCard(
                    title: "Running Session",
                    date: Date().addingTimeInterval(-86400),
                    metrics: [
                        WorkoutMetric(title: "Distance", value: 5.2, unit: "km", iconSystemName: "figure.run"),
                        WorkoutMetric(title: "Pace", value: "5:30", unit: "min/km", iconSystemName: "speedometer")
                    ]
                )
            }
        }
    }
    
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.large) {
            sectionHeader(title: "Badges", description: "Status indicators and tags")
            
            VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                PTCard {
                    VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                        PTLabel("Badge Variants", style: .bodyBold)
                        
                        HStack(spacing: AppTheme.GeneratedSpacing.large) {
                            Badge(text: "Primary")
                            Badge(text: "Secondary", variant: .secondary)
                            Badge(text: "Outline", variant: .outline)
                        }
                        
                        HStack(spacing: AppTheme.GeneratedSpacing.large) {
                            Badge(text: "Destructive", variant: .destructive)
                            Badge(text: "Success", variant: .success)
                        }
                    }
                    .padding()
                }
                
                PTCard {
                    VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                        PTLabel("Status & Counts", style: .bodyBold)
                        
                        HStack(spacing: AppTheme.GeneratedSpacing.large) {
                            Badge(text: "With Icon", icon: Image(systemName: "checkmark.circle.fill"))
                            Badge.status("Active", isActive: true)
                            Badge.status("Inactive", isActive: false)
                            Badge.count(5)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var toastsSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.lg) {
            sectionHeader(title: "Toasts", description: "Notification banners and alerts")
            
            VStack(spacing: AppConstants.Spacing.md) {
                // Show different toast types
                Toast(type: .success, title: "Success", message: "Your action was completed successfully.")
                Toast(type: .error, title: "Error", message: "Something went wrong. Please try again.")
                Toast(type: .warning, title: "Warning", message: "This action might have consequences.")
                Toast(type: .info, title: "Information", message: "Here is some helpful information for you.")
                
                // Toast without message
                Toast(type: .success, title: "Operation complete")
            }
        }
    }
    
    private var spinnersSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.large) {
            sectionHeader(title: "Spinners", description: "Loading indicators")
            
            VStack(spacing: AppTheme.GeneratedSpacing.large) {
                // Size variants
                PTCard {
                    VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                        PTLabel("Sizes", style: .bodyBold)
                        
                        HStack(spacing: AppTheme.GeneratedSpacing.large) {
                            VStack {
                                Spinner(size: .tiny)
                                PTLabel("Tiny", style: .caption)
                            }
                            
                            VStack {
                                Spinner(size: .small)
                                PTLabel("Small", style: .caption)
                            }
                            
                            VStack {
                                Spinner(size: .medium)
                                PTLabel("Medium", style: .caption)
                            }
                            
                            VStack {
                                Spinner(size: .large)
                                PTLabel("Large", style: .caption)
                            }
                        }
                    }
                    .padding()
                }
                
                // Color variants
                PTCard {
                    VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                        PTLabel("Variants", style: .bodyBold)
                        
                        HStack(spacing: AppTheme.GeneratedSpacing.large) {
                            VStack {
                                Spinner(variant: .primary)
                                PTLabel("Primary", style: .caption)
                            }
                            
                            VStack {
                                Spinner(variant: .secondary)
                                PTLabel("Secondary", style: .caption)
                            }
                            
                            ZStack {
                                AppTheme.GeneratedColors.primary
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(AppTheme.GeneratedRadius.medium)
                                
                                VStack {
                                    Spinner(variant: .light)
                                    PTLabel("Light", style: .caption)
                                        .foregroundColor(AppTheme.GeneratedColors.background)
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                // WithLoading example
                PTCard {
                    VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                        PTLabel("WithLoading Wrapper", style: .bodyBold)
                        
                        WithLoading(isLoading: true) {
                            VStack {
                                PTLabel("This content is loading", style: .body)
                                    .padding()
                                    .frame(height: 100)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var headersSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.lg) {
            sectionHeader(title: "Headers", description: "Dashboard and section headers")
            
            VStack(spacing: AppConstants.Spacing.lg) {
                DashboardHeader.greeting(userName: "John Doe")
                
                DashboardHeader.section(title: "Your Workouts", subtitle: "Recent activity")
                
                DashboardHeader(
                    title: "Dashboard",
                    subtitle: "Your daily summary",
                    rightAccessory: {
                        Button(action: {}) {
                            Image(systemName: "gear")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.brassGold)
                        }
                    }
                )
            }
        }
    }
    
    private var listsSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.lg) {
            sectionHeader(title: "Lists", description: "Workout history and leaderboards")
            
            VStack(spacing: AppConstants.Spacing.md) {
                VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                    Text("Workout History")
                        .font(.custom(AppFonts.bodyBold, size: AppConstants.FontSize.md))
                    
                    // Use our sample workout history rows
                    WorkoutHistoryRow(workout: WorkoutHistoryList_Previews.sampleWorkout())
                        .frame(height: 120)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(AppConstants.Radius.md)
                
                VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                    Text("Leaderboard")
                        .font(.custom(AppFonts.bodyBold, size: AppConstants.FontSize.md))
                    
                    LeaderboardRow(
                        rank: 1,
                        name: "Jane Smith",
                        score: "256",
                        avatarURL: nil,
                        isCurrentUser: false
                    )
                    
                    LeaderboardRow(
                        rank: 2,
                        name: "John Doe",
                        score: "221",
                        avatarURL: nil,
                        isCurrentUser: true
                    )
                    
                    LeaderboardRow(
                        rank: 3,
                        name: "Alex Johnson",
                        score: "185",
                        avatarURL: nil,
                        isCurrentUser: false
                    )
                }
                .padding()
                .background(Color.white)
                .cornerRadius(AppConstants.Radius.md)
            }
        }
    }
    
    private var sheetsSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.lg) {
            sectionHeader(title: "Modal Sheets", description: "Settings and filters")
            
            VStack(spacing: AppConstants.Spacing.md) {
                PTButton(
                    title: "Show Settings Sheet",
                    icon: Image(systemName: "gearshape.fill"),
                    action: {
                        showingSettingsSheet = true
                    }
                )
                
                // Show preview of settings content
                VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                    Text("Settings Preview")
                        .font(.custom(AppFonts.bodyBold, size: AppConstants.FontSize.md))
                    
                    Image("settings_preview")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .cornerRadius(AppConstants.Radius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppConstants.Radius.md)
                                .stroke(AppTheme.GeneratedColors.gridlineGray, lineWidth: 1)
                        )
                        .padding(.horizontal)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(AppConstants.Radius.md)
            }
        }
    }
    
    private var typographySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.large) {
            sectionHeader(title: "Typography", description: "Text styles and fonts")
            
            PTCard {
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                    Group {
                        PTLabel("Heading 1", style: .heading, size: .large)
                        PTLabel("Heading 2", style: .heading, size: .medium)
                        PTLabel("Heading 3", style: .heading, size: .small)
                        
                        PTSeparator().padding(.vertical, AppTheme.GeneratedSpacing.extraSmall)
                        
                        PTLabel("Subheading 1", style: .subheading, size: .large)
                        PTLabel("Subheading 2", style: .subheading, size: .medium)
                        
                        PTSeparator().padding(.vertical, AppTheme.GeneratedSpacing.extraSmall)
                        
                        PTLabel("Body Text", style: .body)
                        PTLabel("Body Bold", style: .bodyBold)
                        
                        PTSeparator().padding(.vertical, AppTheme.GeneratedSpacing.extraSmall)
                        
                        PTLabel("Caption", style: .caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppTheme.GeneratedSpacing.medium)
                }
            }
        }
    }
    
    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.large) {
            sectionHeader(title: "Colors", description: "Design system color palette")
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.GeneratedSpacing.medium) {
                colorSwatch("Background", color: AppTheme.GeneratedColors.background)
                colorSwatch("Card Background", color: AppTheme.GeneratedColors.cardBackground)
                colorSwatch("Primary", color: AppTheme.GeneratedColors.primary)
                colorSwatch("Primary Light", color: AppTheme.GeneratedColors.primaryLight)
                colorSwatch("Secondary", color: AppTheme.GeneratedColors.secondary)
                colorSwatch("Accent", color: AppTheme.GeneratedColors.accent)
                colorSwatch("Success", color: AppTheme.GeneratedColors.success)
                colorSwatch("Error", color: AppTheme.GeneratedColors.error)
                colorSwatch("Warning", color: AppTheme.GeneratedColors.warning)
                colorSwatch("Text Primary", color: AppTheme.GeneratedColors.textPrimary)
                colorSwatch("Text Secondary", color: AppTheme.GeneratedColors.textSecondary)
                colorSwatch("Text Tertiary", color: AppTheme.GeneratedColors.textTertiary)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.extraSmall) {
            PTLabel(title, style: .heading)
                .foregroundColor(AppTheme.GeneratedColors.primary)
            
            PTLabel(description, style: .body)
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
        }
    }
    
    private func colorSwatch(_ name: String, color: Color) -> some View {
        VStack(spacing: AppTheme.GeneratedSpacing.extraSmall) {
            Rectangle()
                .fill(color)
                .frame(height: 60)
                .cornerRadius(AppTheme.GeneratedRadius.small)
            
            PTLabel(name, style: .body, size: .small)
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
        }
    }
}

struct ComponentGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ComponentGalleryView()
                .environment(\.colorScheme, .light)
                .previewDisplayName("Light Mode")
            
            ComponentGalleryView()
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark Mode")
        }
    }
} 