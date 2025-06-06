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
                componentSelector
                
                PTSeparator()
                
                // Component content - extracted to a separate view to reduce type-checking complexity
                ComponentGalleryContentView(
                    selectedComponent: selectedComponent,
                    textFieldValue: $textFieldValue,
                    passwordValue: $passwordValue,
                    showingSettingsSheet: $showingSettingsSheet
                )
            }
            .navigationTitle("Component Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSettingsSheet) {
                // Display settings sheet when triggered
                let mockAuth: AuthViewModel = {
                    let auth = AuthViewModel()
                    // Create a mock user using the User typealias (which is AuthUserModel)
                    auth.setMockUser(User(
                        id: "preview", 
                        email: "user@example.com", 
                        firstName: "Preview", 
                        lastName: "User",
                        profilePictureUrl: nil
                    ))
                    return auth
                }()
                
                SettingsSheet()
                    .environmentObject(mockAuth)
            }
        }
    }
    
    // MARK: - Component Selector
    
    private var componentSelector: some View {
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
                            .background(selectedComponent == index ? AppTheme.GeneratedColors.primary.opacity(0.2) : Color.clear)
                            .cornerRadius(AppTheme.GeneratedRadius.full)
                    }
                }
            }
            .padding(.horizontal, AppTheme.GeneratedSpacing.medium)
        }
        .padding(.vertical, AppTheme.GeneratedSpacing.small)
        .background(AppTheme.GeneratedColors.cardBackground)
    }
}

// MARK: - Component Gallery Content
// Extracted to a separate struct to reduce type-checking complexity
struct ComponentGalleryContentView: View {
    let selectedComponent: Int
    @Binding var textFieldValue: String
    @Binding var passwordValue: String
    @Binding var showingSettingsSheet: Bool
    
    var body: some View {
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
    
    // MARK: - Component Sections
    
    private var buttonsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.large) {
            sectionHeader(title: "Buttons", description: "Button components with different variants")
            
            VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                // Use a typed local variable to resolve ambiguity
                let coreButtonStyle: PTButton.ButtonStyle = .primary
                PTButton("Primary Button", style: coreButtonStyle) {}
                
                // Use a typed local variable to resolve ambiguity for secondary style
                let secondaryButtonStyle: PTButton.ButtonStyle = .secondary
                PTButton("Secondary Button", style: secondaryButtonStyle) {
                    // action
                }
                
                // Explicitly specify the type for outline style
                let outlineButtonStyle: PTButton.ExtendedStyle = .outline
                PTButton("Outline Button", style: outlineButtonStyle) {
                    // action
                }
                
                // Explicitly specify the type for ghost style
                let ghostButtonStyle: PTButton.ExtendedStyle = .ghost
                PTButton("Ghost Button", style: ghostButtonStyle) {
                    // action
                }
                
                // Use a typed local variable to resolve ambiguity for destructive style
                let destructiveButtonStyle: PTButton.ButtonStyle = .destructive
                PTButton("Destructive Button", style: destructiveButtonStyle) {
                    // action
                }
                
                // Since PTButton might not have loading state built in yet, 
                // you may need to create your own loading button or extend PTButton
                
                PTSeparator().padding(.vertical, AppTheme.GeneratedSpacing.small)
                
                HStack(spacing: AppTheme.GeneratedSpacing.medium) {
                    // Explicitly specify the style to avoid ambiguity
                    let defaultStyle: PTButton.ExtendedStyle = .primary
                    
                    PTButton("Small", style: defaultStyle) {
                        // action
                    }
                    .padding(.vertical, 4)
                    
                    PTButton("Medium", style: defaultStyle) {
                        // action
                    }
                    
                    PTButton("Large", style: defaultStyle) {
                        // action
                    }
                    .padding(.vertical, 16)
                }
            }
        }
    }
    
    private var textFieldsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.large) {
            sectionHeader(title: "Text Fields", description: "Text input components with different states")
            
            VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                // Standard PTTextField
                PTLabel("Standard PTTextField", style: .bodyBold)
                    .padding(.top, AppTheme.GeneratedSpacing.small)
                
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
                
                // Error state
                PTTextField(
                    "Enter username",
                    text: .constant("j"),
                    label: "Username"
                )
                
                // FocusableTextField demonstration
                PTLabel("FocusableTextField (with focus ring)", style: .bodyBold)
                    .padding(.top, AppTheme.GeneratedSpacing.medium)
                
                FocusableTextField(
                    "Email Address",
                    text: .constant("user@example.com"),
                    label: "Email",
                    keyboardType: .emailAddress,
                    icon: Image(systemName: "envelope")
                )
                
                FocusableTextField(
                    "Password",
                    text: $passwordValue,
                    label: "Password",
                    isSecure: true,
                    icon: Image(systemName: "lock")
                )
                
                // Advanced usage
                PTLabel("PTTextField with focus extension", style: .bodyBold)
                    .padding(.top, AppTheme.GeneratedSpacing.medium)
                
                @FocusState var isAdvancedFieldFocused: Bool
                
                PTTextField(
                    "Advanced example", 
                    text: .constant("With focus ring extension"),
                    label: "Enhanced Field",
                    icon: Image(systemName: "star")
                )
                .withFocusRing($isAdvancedFieldFocused)
            }
        }
    }
    
    private var metricCardsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.large) {
            sectionHeader(title: "Metric Cards", description: "Cards displaying key metrics and stats")
            
            VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                HStack(spacing: AppTheme.GeneratedSpacing.medium) {
                    MetricCardView(
                        MetricData(
                            title: "TOTAL WORKOUTS",
                            value: 42,
                            icon: Image(systemName: "flame.fill")
                        )
                    )
                    .frame(maxWidth: .infinity)
                    
                    MetricCardView(
                        MetricData(
                            title: "DISTANCE", 
                            value: 8.5, 
                            unit: "km",
                            icon: Image(systemName: "figure.run")
                        )
                    )
                    .frame(maxWidth: .infinity)
                }
                
                MetricCardView(
                    MetricData(
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
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.large) {
            sectionHeader(title: "Toasts", description: "Notification banners and alerts")
            
            VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                // Show different toast types
                Toast(type: .success, title: "Success", message: "Your action was completed successfully.")
                Toast(type: .error, title: "Error", message: "Something went wrong. Please try again.")
                Toast(type: .warning, title: "Warning", message: "This action might have consequences.")
                Toast(type: .info, title: "Information", message: "Here is some helpful information for you.")
                
                // Toast without message
                Toast(type: .success, title: "Operation complete", message: "")
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
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.large) {
            sectionHeader(title: "Headers", description: "Dashboard and section headers")
            
            VStack(spacing: AppTheme.GeneratedSpacing.large) {
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
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                        }
                    }
                )
            }
        }
    }
    
    private var listsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.large) {
            sectionHeader(title: "Lists", description: "Workout history and leaderboards")
            
            VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                    PTLabel("Workout History", style: .bodyBold)
                    
                    // Convert WorkoutHistory to WorkoutResultSwiftData
                    let sampleWorkout = WorkoutHistoryList_Previews.sampleWorkout()
                    let result = WorkoutResultSwiftData(
                        exerciseType: sampleWorkout.exerciseType,
                        startTime: sampleWorkout.date,
                        endTime: sampleWorkout.date.addingTimeInterval(sampleWorkout.duration),
                        durationSeconds: Int(sampleWorkout.duration),
                        repCount: sampleWorkout.reps,
                        distanceMeters: sampleWorkout.distance
                    )
                    
                    WorkoutHistoryRow(result: result)
                        .frame(height: 120)
                }
                .padding()
                .background(AppTheme.GeneratedColors.cardBackground)
                .cornerRadius(AppTheme.GeneratedRadius.medium)
                
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                    PTLabel("Leaderboard", style: .bodyBold)
                    
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
                .background(AppTheme.GeneratedColors.cardBackground)
                .cornerRadius(AppTheme.GeneratedRadius.medium)
            }
        }
    }
    
    private var sheetsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.large) {
            sectionHeader(title: "Modal Sheets", description: "Settings and filters")
            
            VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                // Use a typed local variable to resolve ambiguity
                let coreButtonStyle: PTButton.ButtonStyle = .primary
                PTButton("Show Settings Sheet", 
                         style: coreButtonStyle,
                         icon: Image(systemName: "gearshape.fill")) {
                    showingSettingsSheet = true
                }
                
                // Show preview of settings content
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                    PTLabel("Settings Preview", style: .bodyBold)
                    
                    Image("settings_preview")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .cornerRadius(AppTheme.GeneratedRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.medium)
                                .stroke(AppTheme.GeneratedColors.textTertiary.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                }
                .padding()
                .background(AppTheme.GeneratedColors.cardBackground)
                .cornerRadius(AppTheme.GeneratedRadius.medium)
            }
        }
    }
    
    private var typographySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.large) {
            sectionHeader(title: "Typography", description: "Text styles and fonts")
            
            PTCard {
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                    Group {
                        PTLabel.sized("Heading 1", style: .heading, size: .large)
                        PTLabel.sized("Heading 2", style: .heading, size: .medium)
                        PTLabel.sized("Heading 3", style: .heading, size: .small)
                        
                        PTSeparator().padding(.vertical, AppTheme.GeneratedSpacing.extraSmall)
                        
                        PTLabel.sized("Subheading 1", style: .subheading, size: .large)
                        PTLabel.sized("Subheading 2", style: .subheading, size: .medium)
                        
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
                colorSwatch("Primary Light", color: AppTheme.GeneratedColors.primary.opacity(0.2))
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
            
            PTLabel.sized(name, style: .caption, size: .medium)
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