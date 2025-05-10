import SwiftUI
import PTDesignSystem
import SwiftData

// Define ActivityFeedItem struct
struct ActivityFeedItem: Identifiable {
    let id = UUID()
    let text: String
    let date: Date
    let icon: String // Added icon for visual variety
}

// Sample Activity Data
let sampleActivities: [ActivityFeedItem] = [
    ActivityFeedItem(text: "Completed Push-Up Challenge", date: Date().addingTimeInterval(-120), icon: "flame.fill"), // 2 min ago
    ActivityFeedItem(text: "Set a new Personal Best in Sit-Ups", date: Date().addingTimeInterval(-3600 * 3), icon: "star.fill"), // 3 hours ago
    ActivityFeedItem(text: "Logged 5 workouts this week", date: Date().addingTimeInterval(-3600 * 24 * 2), icon: "figure.walk"), // 2 days ago
    ActivityFeedItem(text: "Joined the 'Monthly Fitness' leaderboard", date: Date().addingTimeInterval(-3600 * 24 * 5), icon: "rosette") // 5 days ago
]

// Helper to format dates relatively
func relativeDateFormatter(date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: date, relativeTo: Date())
}

struct DashboardView: View {
    // Keep track of the constants we need
    private static let cardGap: CGFloat = AppTheme.GeneratedSpacing.itemSpacing
    private static let globalPadding: CGFloat = AppTheme.GeneratedSpacing.contentPadding
    
    // Use the correct type for AuthViewModel with full qualifier
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.modelContext) private var modelContext
    
    @State private var statCardsVisible = [false, false, false, false] // ADDED for animation
    @State private var quickLinksVisible = false // ADDED for animation
    @State private var recentActivityVisible = false // ADDED for animation
    @State private var showingStyleShowcase = false // Added for style showcase
    
    // For haptics on Start Workout button
    // private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium) // Removed as button is removed
    
    // Quick links for navigation
    private let quickLinks: [(title: String, icon: String, destination: String, isSystemIcon: Bool)] = [
        ("Push-Ups", "pushup", "workout-pushups", false),
        ("Sit-Ups", "situp", "workout-situps", false),
        ("Pull-Ups", "pullup", "workout-pullups", false),
        ("Running", "running", "workout-running", false)
    ]
    
    var body: some View {
        NavigationView {
            ZStack { // ADDED ZStack for gradient background
                // Ambient Background Gradient
                RadialGradient(
                    gradient: Gradient(colors: [
                        // Make center slightly lighter than main background, or use a very light compatible color
                        AppTheme.GeneratedColors.background.opacity(0.9), // Assuming background is opaque, making it slightly more transparent in center effectively lightens against a base
                        AppTheme.GeneratedColors.background
                    ]),
                    center: .center,
                    startRadius: 50,
                    endRadius: UIScreen.main.bounds.height * 0.6 // Adjust endRadius as needed
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: Self.cardGap) {
                        // 4-1: Dynamic greeting with user's name
                        greetingHeaderView() // Call the new helper method
                        
                        // 4-2: Quick Stats Card Grid
                        quickStatsGridView() // Call the new helper method for stat cards
                        
                        // 4-3: Primary Call-to-Action - Now a static header
                        PTLabel("Start Workout", style: .heading)
                            .padding(.top, 16)
                            .frame(maxWidth: .infinity, alignment: .leading) // Ensure it aligns with the grid below
                            // .padding(.horizontal, Self.globalPadding) // Already handled by VStack's padding

                        // 4-4: Quick Links Section
                        quickLinksSectionView() // Call the new helper method

                        // NEW: Activity Feed Section
                        activityFeedSectionView() // Call the new helper method
                        
                        // NEW: Design Showcase Button (only in DEBUG builds)
                        #if DEBUG
                        Button {
                            showingStyleShowcase = true
                        } label: {
                            HStack {
                                Image(systemName: "paintbrush.fill")
                                Text("MILITARY UI SHOWCASE")
                                    .militaryMonospaced(size: 14)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.GeneratedColors.brassGold.opacity(0.15))
                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.button)
                                    .stroke(AppTheme.GeneratedColors.brassGold, lineWidth: 1)
                            )
                            .cornerRadius(AppTheme.GeneratedRadius.button)
                        }
                        .padding(.horizontal)
                        .padding(.top, AppTheme.GeneratedSpacing.large)
                        #endif
                        
                        Spacer()
                    }
                    .padding(Self.globalPadding)
                }
            }
            .accessibilityLabel("You have \(viewModel.totalWorkouts) workouts logged")
            .onAppear {
                viewModel.setModelContext(modelContext)
                animateContentIn()
            }
            .refreshable {
                viewModel.refresh()
                // Optionally reset animation states on refresh if desired
            }
            .sheet(isPresented: $showingStyleShowcase) {
                MilitaryStyleShowcase()
            }
        }
    }
    
    // New helper method for the greeting header
    @ViewBuilder
    private func greetingHeaderView() -> some View {
        HStack(spacing: 0) {
            Text("Good \(viewModel.timeOfDayGreeting), ")
            Text(authViewModel.displayName)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            AppTheme.GeneratedColors.brassGold.opacity(0.9), // Lighter gold at top
                            AppTheme.GeneratedColors.brassGold // Standard gold at bottom
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .font(AppTheme.GeneratedTypography.bodyBold(size: AppTheme.GeneratedTypography.heading2))
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, AppTheme.GeneratedSpacing.medium)
    }
    
    // New helper method for the quick stats grid
    @ViewBuilder
    private func quickStatsGridView() -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: Self.cardGap),
            GridItem(.flexible(), spacing: Self.cardGap)
        ], spacing: Self.cardGap) {
            statCard(at: 0, data: MetricData(title: "Last Score", value: viewModel.lastScoreString), trend: viewModel.lastScoreTrend)
            statCard(at: 1, data: MetricData(title: "7-Day Push-Ups", value: viewModel.weeklyReps), trend: viewModel.weeklyPushupTrend)
            statCard(at: 2, data: MetricData(title: "Monthly Workouts", value: viewModel.monthlyWorkouts))
            statCard(at: 3, data: MetricData(title: "Personal Best", value: viewModel.personalBest))
        }
    }
    
    // New helper method for the primary call to action button - REMOVED
    /*
    @ViewBuilder
    private func primaryCallToActionView() -> some View {
        NavigationLink(destination: WorkoutSelectionView()) {
            // Use a typed local variable to resolve ambiguity
            let coreButtonStyle: PTButton.ButtonStyle = .primary
            PTButton("Start Workout", style: coreButtonStyle) {
                // hapticGenerator.impactOccurred() // hapticGenerator is removed
                // Original button action would go here if it wasn't just for NavLink label
                // Since this PTButton is just a label for a NavigationLink,
                // the haptic on the PTButton's action might not fire as expected
                // if the NavigationLink itself handles the tap first.
                // A more reliable way for NavLink haptics was the .onTapGesture on the QuickLinkCard's NavLink.
                // For a pure button, this action block is the place.
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle()) // Remove NavigationLink styling
        .padding(.vertical, AppTheme.GeneratedSpacing.itemSpacing)
    }
    */

    // New helper method for the Quick Links section
    @ViewBuilder
    private func quickLinksSectionView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // REMOVED "QUICK LINKS" Text and PTSeparator
            // Text("QUICK LINKS")
            //     .militaryMonospaced(size: AppTheme.GeneratedTypography.small)
            //     .foregroundColor(AppTheme.GeneratedColors.textSecondary)
            //     .padding(.top, AppTheme.GeneratedSpacing.large)
            //     .padding(.bottom, AppTheme.GeneratedSpacing.small)
            // PTSeparator().padding(.bottom, AppTheme.GeneratedSpacing.small)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Self.cardGap),
                GridItem(.flexible(), spacing: Self.cardGap)
            ], spacing: Self.cardGap) {
                ForEach(quickLinks.indices, id: \.self) { index in
                    let link = quickLinks[index]
                    QuickLinkCard(title: link.title, icon: link.icon, destination: link.destination, isSystemIcon: link.isSystemIcon)
                }
            }
            .opacity(quickLinksVisible ? 1 : 0)
            .offset(y: quickLinksVisible ? 0 : 15)
        }
    }
    
    // New helper method for the Activity Feed section
    @ViewBuilder
    private func activityFeedSectionView() -> some View {
        if !sampleActivities.isEmpty { // Show only if there are activities
            Group {
                Text("ACTIVITY FEED")
                    .militaryMonospaced(size: AppTheme.GeneratedTypography.small)
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    .padding(.top, AppTheme.GeneratedSpacing.large)
                    .padding(.bottom, AppTheme.GeneratedSpacing.small)
                
                PTSeparator().padding(.bottom, AppTheme.GeneratedSpacing.small)

                TimelineView(.periodic(from: Date(), by: 60.0)) { context in
                    let displayedActivities = Array(sampleActivities.prefix(3)) // Ensure it's an Array for indexed access
                    
                    VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                        ForEach(displayedActivities.indices, id: \.self) { index in
                            let activity = displayedActivities[index]
                            HStack { 
                                Image(systemName: activity.icon)
                                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                                    .frame(width: 20, alignment: .center)
                                VStack(alignment: .leading) {
                                    PTLabel(activity.text, style: .body)
                                        .lineLimit(2)
                                    PTLabel(relativeDateFormatter(date: activity.date), style: .caption)
                                        .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                                }
                                Spacer() 
                            }
                            .padding(.vertical, AppTheme.GeneratedSpacing.extraSmall) 
                            
                            // Always render separator, control by opacity, use simple color
                            PTSeparator(color: Color.gray.opacity(0.5)) // Simplified color
                                .opacity(index < displayedActivities.count - 1 ? 1 : 0)
                        }
                    }
                    .padding(AppTheme.GeneratedSpacing.itemSpacing)
                    .background(AppTheme.GeneratedColors.cardBackground)
                    .cornerRadius(AppTheme.GeneratedRadius.medium)
                }
            }
            // MODIFIED: Uncommented animation modifiers for recent activity feed
            .opacity(recentActivityVisible ? 1 : 0)
            .offset(y: recentActivityVisible ? 0 : 15)
        } else {
            EmptyView()
        }
    }
    
    // Helper to build stat cards with animation modifiers
    @ViewBuilder
    private func statCard(at index: Int, data: MetricData, trend: TrendDirection? = nil) -> some View {
        MetricCardView(data, trend: trend)
            .opacity(statCardsVisible[index] ? 1 : 0)
            .offset(y: statCardsVisible[index] ? 0 : 15) // Slide up by 15 points
            .animation(.easeOut.delay(Double(index) * 0.1), value: statCardsVisible[index])
    }
    
    private func animateContentIn() {
        // Reset states for re-animation if view appears again (e.g. tab switch)
        statCardsVisible = [false, false, false, false]
        quickLinksVisible = false
        recentActivityVisible = false
        
        let baseDelay = 0.1 // Base delay before first animation
        let staggerDelay = 0.075 // Delay between each staggered item

        for i in 0..<statCardsVisible.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + baseDelay + (Double(i) * staggerDelay)) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.2)) {
                    statCardsVisible[i] = true
                }
            }
        }
        
        let quickLinksDelay = baseDelay + (Double(statCardsVisible.count) * staggerDelay)
        DispatchQueue.main.asyncAfter(deadline: .now() + quickLinksDelay) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.2)) {
                quickLinksVisible = true
            }
        }
        
        let recentActivityDelay = quickLinksDelay + staggerDelay // Start after quick links
        DispatchQueue.main.asyncAfter(deadline: .now() + recentActivityDelay) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.2)) {
                recentActivityVisible = true
            }
        }
    }
}

// Quick Link Card component
struct QuickLinkCard: View {
    let title: String
    let icon: String
    let destination: String
    let isSystemIcon: Bool
    
    // For haptics - REMOVED as it's part of NavigationLink, not a separate button interaction here.
    // private let hapticGenerator = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        NavigationLink(destination: destinationView) {
            PTCard {
                VStack(alignment: .center, spacing: AppTheme.GeneratedSpacing.extraSmall) { // Changed to VStack
                    if isSystemIcon {
                        Image(systemName: icon)
                            .font(.system(size: 48)) // Increased icon size, .font for system icons
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                            .frame(width: 64, height: 64) // Larger frame for icon
                            .scaledToFit()
                    } else {
                        Image(icon)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary) // color applied if it's a template image
                            .frame(width: 64, height: 64) // Larger frame for icon
                    }
                    
                    Text(title)
                        // Use system monospaced font, adjust size as needed
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        .lineLimit(1) // Ensure single line, names are short now
                        .multilineTextAlignment(.center) // Center text below icon
                }
                .padding(AppTheme.GeneratedSpacing.itemSpacing)
                .frame(maxWidth: .infinity) // Ensure VStack takes full width of PTCard
            }
            .frame(height: 120) // Increased card height to accommodate larger icon and text
        }
        .buttonStyle(PlainButtonStyle()) // Ensure NavigationLink doesn't add its own styling to the card
    }
    
    // Determine the destination view based on the destination string
    @ViewBuilder
    private var destinationView: some View {
        switch destination {
        case "workout-pushups":
            WorkoutSessionView(exerciseName: "Push-Ups") // Assuming WorkoutSessionView expects "Push-Ups"
        case "workout-situps":
            WorkoutSessionView(exerciseName: "Sit-Ups")  // Assuming WorkoutSessionView expects "Sit-Ups"
        case "workout-pullups":
            WorkoutSessionView(exerciseName: "Pull-Ups")
        case "workout-running":
            RunWorkoutView() // Assuming RunWorkoutView is the correct destination
        default:
            Text("Unknown Destination: \(destination)")
                .padding()
        }
    }
}

#Preview {
    // Simple placeholder to fix build errors
    DashboardView()
        .environmentObject(AuthViewModel())
} 