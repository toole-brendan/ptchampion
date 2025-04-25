import SwiftUI

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
                    HStack(spacing: AppConstants.Spacing.md) {
                        ForEach(0..<components.count, id: \.self) { index in
                            Button(action: {
                                withAnimation {
                                    selectedComponent = index
                                }
                            }) {
                                Text(components[index])
                                    .font(.custom(AppFonts.bodyBold, size: AppConstants.FontSize.sm))
                                    .foregroundColor(selectedComponent == index ? .deepOpsGreen : .tacticalGray)
                                    .padding(.vertical, AppConstants.Spacing.sm)
                                    .padding(.horizontal, AppConstants.Spacing.md)
                                    .background(selectedComponent == index ? Color.brassGold.opacity(0.15) : Color.clear)
                                    .cornerRadius(AppConstants.Radius.full)
                            }
                        }
                    }
                    .padding(.horizontal, AppConstants.Spacing.md)
                }
                .padding(.vertical, AppConstants.Spacing.sm)
                .background(Color.white)
                
                Divider()
                
                // Component content
                ScrollView {
                    VStack(spacing: AppConstants.Spacing.xl) {
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
                .background(Color.tacticalCream.opacity(0.5))
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
        VStack(alignment: .leading, spacing: AppConstants.Spacing.lg) {
            sectionHeader(title: "Buttons", description: "Button components with different variants")
            
            VStack(spacing: AppConstants.Spacing.md) {
                PTButton(title: "Primary Button", action: {})
                
                PTButton(
                    title: "Secondary Button",
                    icon: Image(systemName: "arrow.right"),
                    action: {},
                    variant: .secondary
                )
                
                PTButton(
                    title: "Outline Button",
                    action: {},
                    variant: .outline,
                    isFullWidth: true
                )
                
                PTButton(
                    title: "Ghost Button",
                    action: {},
                    variant: .ghost
                )
                
                PTButton(
                    title: "Destructive Button",
                    icon: Image(systemName: "trash"),
                    action: {},
                    variant: .destructive
                )
                
                PTButton(
                    title: "Loading Button",
                    action: {},
                    isLoading: true
                )
                
                Divider().padding(.vertical, AppConstants.Spacing.sm)
                
                HStack(spacing: AppConstants.Spacing.md) {
                    PTButton(
                        title: "Small",
                        action: {},
                        size: .small
                    )
                    
                    PTButton(
                        title: "Medium",
                        action: {},
                        size: .medium
                    )
                    
                    PTButton(
                        title: "Large",
                        action: {},
                        size: .large
                    )
                }
            }
        }
    }
    
    private var textFieldsSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.lg) {
            sectionHeader(title: "Text Fields", description: "Text input components with different states")
            
            VStack(spacing: AppConstants.Spacing.md) {
                // Empty state
                PTTextField(
                    text: $textFieldValue,
                    label: "Username",
                    placeholder: "Enter username"
                )
                
                // With icon
                PTTextField(
                    text: .constant("johndoe"),
                    label: "Username",
                    placeholder: "Enter username",
                    icon: Image(systemName: "person"),
                    validationState: .valid
                )
                
                // Error state
                PTTextField(
                    text: .constant("j"),
                    label: "Username",
                    placeholder: "Enter username",
                    validationState: .invalid(message: "Username must be at least 3 characters")
                )
                
                // Password field
                PTTextField(
                    text: $passwordValue,
                    label: "Password",
                    placeholder: "Enter password",
                    icon: Image(systemName: "lock"),
                    isSecure: true
                )
                
                // Email with keyboard type
                PTTextField(
                    text: .constant("user@example.com"),
                    label: "Email Address",
                    placeholder: "Enter email",
                    icon: Image(systemName: "envelope"),
                    keyboardType: .emailAddress
                )
            }
        }
    }
    
    private var metricCardsSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.lg) {
            sectionHeader(title: "Metric Cards", description: "Cards displaying key metrics and stats")
            
            VStack(spacing: AppConstants.Spacing.md) {
                HStack(spacing: AppConstants.Spacing.md) {
                    MetricCard(
                        title: "TOTAL WORKOUTS",
                        value: 42,
                        icon: Image(systemName: "flame.fill")
                    )
                    .frame(maxWidth: .infinity)
                    
                    MetricCard(
                        title: "DISTANCE", 
                        value: 8.5, 
                        unit: "km",
                        icon: Image(systemName: "figure.run")
                    )
                    .frame(maxWidth: .infinity)
                }
                
                MetricCard(
                    title: "LAST ACTIVITY",
                    value: "Pull-ups",
                    description: "Yesterday - 42 reps",
                    icon: Image(systemName: "clock")
                )
            }
        }
    }
    
    private var workoutCardsSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.lg) {
            sectionHeader(title: "Workout Cards", description: "Cards displaying workout details")
            
            VStack(spacing: AppConstants.Spacing.md) {
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
        VStack(alignment: .leading, spacing: AppConstants.Spacing.lg) {
            sectionHeader(title: "Badges", description: "Status indicators and tags")
            
            VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                    Text("Badge Variants")
                        .font(.custom(AppFonts.bodyBold, size: AppConstants.FontSize.sm))
                    
                    HStack(spacing: AppConstants.Spacing.lg) {
                        Badge(text: "Primary")
                        Badge(text: "Secondary", variant: .secondary)
                        Badge(text: "Outline", variant: .outline)
                    }
                    
                    HStack(spacing: AppConstants.Spacing.lg) {
                        Badge(text: "Destructive", variant: .destructive)
                        Badge(text: "Success", variant: .success)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(AppConstants.Radius.md)
                
                VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                    Text("Status & Counts")
                        .font(.custom(AppFonts.bodyBold, size: AppConstants.FontSize.sm))
                    
                    HStack(spacing: AppConstants.Spacing.lg) {
                        Badge(text: "With Icon", icon: Image(systemName: "checkmark.circle.fill"))
                        Badge.status("Active", isActive: true)
                        Badge.status("Inactive", isActive: false)
                        Badge.count(5)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(AppConstants.Radius.md)
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
        VStack(alignment: .leading, spacing: AppConstants.Spacing.lg) {
            sectionHeader(title: "Spinners", description: "Loading indicators")
            
            VStack(spacing: AppConstants.Spacing.lg) {
                // Size variants
                VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                    Text("Sizes")
                        .font(.custom(AppFonts.bodyBold, size: AppConstants.FontSize.sm))
                    
                    HStack(spacing: AppConstants.Spacing.xl) {
                        VStack {
                            Spinner(size: .tiny)
                            Text("Tiny").font(.caption2)
                        }
                        
                        VStack {
                            Spinner(size: .small)
                            Text("Small").font(.caption2)
                        }
                        
                        VStack {
                            Spinner(size: .medium)
                            Text("Medium").font(.caption2)
                        }
                        
                        VStack {
                            Spinner(size: .large)
                            Text("Large").font(.caption2)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(AppConstants.Radius.md)
                
                // Color variants
                VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                    Text("Variants")
                        .font(.custom(AppFonts.bodyBold, size: AppConstants.FontSize.sm))
                    
                    HStack(spacing: AppConstants.Spacing.xl) {
                        VStack {
                            Spinner(variant: .primary)
                            Text("Primary").font(.caption2)
                        }
                        
                        VStack {
                            Spinner(variant: .secondary)
                            Text("Secondary").font(.caption2)
                        }
                        
                        ZStack {
                            Color.deepOpsGreen
                                .frame(width: 60, height: 60)
                                .cornerRadius(AppConstants.Radius.md)
                            
                            VStack {
                                Spinner(variant: .light)
                                Text("Light")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(AppConstants.Radius.md)
                
                // WithLoading example
                VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                    Text("WithLoading Wrapper")
                        .font(.custom(AppFonts.bodyBold, size: AppConstants.FontSize.sm))
                    
                    WithLoading(isLoading: true) {
                        VStack {
                            Text("This content is loading")
                                .padding()
                                .frame(height: 100)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(AppConstants.Radius.md)
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
                                .stroke(Color.gridlineGray, lineWidth: 1)
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
        VStack(alignment: .leading, spacing: AppConstants.Spacing.lg) {
            sectionHeader(title: "Typography", description: "Text styles and fonts")
            
            VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                Group {
                    Text("Heading 1").headingStyle(size: 28)
                    Text("Heading 2").headingStyle(size: 24)
                    Text("Heading 3").headingStyle(size: 20)
                    
                    Divider().padding(.vertical, AppConstants.Spacing.xs)
                    
                    Text("Subheading 1").subheadingStyle(size: 19)
                    Text("Subheading 2").subheadingStyle(size: 16)
                    
                    Divider().padding(.vertical, AppConstants.Spacing.xs)
                    
                    Text("Body Text").font(.custom(AppFonts.body, size: 16)).foregroundColor(.commandBlack)
                    Text("Body Bold").font(.custom(AppFonts.bodyBold, size: 16)).foregroundColor(.commandBlack)
                    
                    Divider().padding(.vertical, AppConstants.Spacing.xs)
                    
                    Text("123456").statsNumberStyle()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppConstants.Spacing.md)
                .background(Color.white)
                .cornerRadius(AppConstants.Radius.md)
            }
        }
    }
    
    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.lg) {
            sectionHeader(title: "Colors", description: "Color palette")
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppConstants.Spacing.md) {
                colorSwatch("Tactical Cream", color: .tacticalCream)
                colorSwatch("Deep Ops Green", color: .deepOpsGreen)
                colorSwatch("Brass Gold", color: .brassGold)
                colorSwatch("Army Tan", color: .armyTan)
                colorSwatch("Olive Mist", color: .oliveMist)
                colorSwatch("Command Black", color: .commandBlack)
                colorSwatch("Tactical Gray", color: .tacticalGray)
                colorSwatch("Gridline Gray", color: .gridlineGray)
                colorSwatch("Inactive Gray", color: .inactiveGray)
                colorSwatch("Tomahawk Red", color: .tomahawkRed)
                colorSwatch("Success Green", color: .successGreen)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
            Text(title)
                .font(.custom(AppFonts.heading, size: AppConstants.FontSize.xl))
                .foregroundColor(.deepOpsGreen)
            
            Text(description)
                .font(.custom(AppFonts.body, size: AppConstants.FontSize.sm))
                .foregroundColor(.tacticalGray)
        }
    }
    
    private func colorSwatch(_ name: String, color: Color) -> some View {
        VStack(spacing: AppConstants.Spacing.xs) {
            Rectangle()
                .fill(color)
                .frame(height: 60)
                .cornerRadius(AppConstants.Radius.sm)
            
            Text(name)
                .font(.custom(AppFonts.body, size: AppConstants.FontSize.xs))
                .foregroundColor(.tacticalGray)
        }
    }
}

struct ComponentGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        ComponentGalleryView()
    }
} 