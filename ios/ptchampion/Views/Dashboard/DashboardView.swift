import SwiftUI
import PTDesignSystem
import SwiftData

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
    
    // For haptics on Start Workout button
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // Quick links for navigation
    private let quickLinks: [(title: String, icon: String, destination: String, isSystemIcon: Bool)] = [
        ("Begin Push-Ups", "pushup", "workout-pushups", false),
        ("Begin Sit-Ups", "situp", "workout-situps", false),
        ("View Leaderboard", "list.star", "leaderboard", true),
        ("Check Progress", "chart.line.uptrend.xyaxis", "progress", true)
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
                        
                        // 4-2: Quick Stats Card Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: Self.cardGap),
                            GridItem(.flexible(), spacing: Self.cardGap)
                        ], spacing: Self.cardGap) {
                            statCard(at: 0, data: MetricData(title: "Last Score", value: viewModel.lastScoreString), trend: viewModel.lastScoreTrend)
                            statCard(at: 1, data: MetricData(title: "7-Day Push-Ups", value: viewModel.weeklyReps), trend: viewModel.weeklyPushupTrend)
                            statCard(at: 2, data: MetricData(title: "Monthly Workouts", value: viewModel.monthlyWorkouts))
                            statCard(at: 3, data: MetricData(title: "Personal Best", value: viewModel.personalBest))
                        }
                        
                        // 4-3: Primary Call-to-Action
                        NavigationLink(destination: WorkoutSelectionView()) {
                            PTButton("Start Workout") {
                                hapticGenerator.impactOccurred()
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
                        
                        // 4-4: Quick Links Section
                        PTLabel("Quick Links", style: .subheading)
                            .padding(.top, AppTheme.GeneratedSpacing.large)
                        PTSeparator().padding(.bottom, AppTheme.GeneratedSpacing.small)
                        
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
                        
                        // 4-5: Activity Feed (Optional)
                        if viewModel.totalWorkouts > 0 {
                            Group { // WRAP content in Group
                                PTLabel("Recent Activity", style: .subheading)
                                    .padding(.top, AppTheme.GeneratedSpacing.large)
                                PTSeparator().padding(.bottom, AppTheme.GeneratedSpacing.small)
                                
                                PTCard {
                                    HStack {
                                        PTLabel("🏅", style: .heading)
                                        
                                        VStack(alignment: .leading) {
                                            PTLabel("Latest Achievement", style: .bodyBold)
                                                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                                            
                                            // Use the new latestAchievement property from ViewModel
                                            PTLabel(viewModel.latestAchievement, style: .body) 
                                                .font(.system(size: 14))
                                                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(AppTheme.GeneratedSpacing.itemSpacing)
                                }
                                .transition(.move(edge: .top))
                            } // END Group
                            .opacity(recentActivityVisible ? 1 : 0) // Apply to Group
                            .offset(y: recentActivityVisible ? 0 : 15) // Apply to Group
                        }
                        
                        Spacer()
                    }
                    .padding(Self.globalPadding)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityLabel("You have \(viewModel.totalWorkouts) workouts logged")
            .onAppear {
                viewModel.setModelContext(modelContext)
                animateContentIn()
            }
            .refreshable {
                viewModel.refresh()
                // Optionally reset animation states on refresh if desired
            }
        }
    }
    
    // Helper to build stat cards with animation modifiers
    @ViewBuilder
    private func statCard(at index: Int, data: MetricData, trend: TrendDirection? = nil) -> some View {
        MetricCardView(data, trend: trend)
            .opacity(statCardsVisible[index] ? 1 : 0)
            .offset(y: statCardsVisible[index] ? 0 : 15) // Slide up by 15 points
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
    
    // For haptics
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        NavigationLink(destination: destinationView) {
            PTCard {
                HStack(alignment: .top) {
                    if isSystemIcon {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                            .frame(width: 24, height: 24)
                            .padding(.top, 2)
                    } else {
                        Image(icon)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                            .frame(width: 24, height: 24)
                            .padding(.top, 2)
                    }
                    
                    PTLabel(title, style: .body)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        .padding(.leading, AppTheme.GeneratedSpacing.extraSmall)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(AppTheme.GeneratedSpacing.itemSpacing)
            }
            .frame(height: 70)
        }
    }
    
    // Determine the destination view based on the destination string
    @ViewBuilder
    private var destinationView: some View {
        switch destination {
        case "workout-pushups":
            WorkoutSessionView(exerciseName: "Push-Ups") // Assuming WorkoutSessionView expects "Push-Ups"
        case "workout-situps":
            WorkoutSessionView(exerciseName: "Sit-Ups")  // Assuming WorkoutSessionView expects "Sit-Ups"
        case "leaderboard":
            // This creates a new VM instance each time. For shared state, this VM should be passed in or be an EnvironmentObject.
            LeaderboardView(viewModel: LeaderboardViewModel(), viewId: "dashboard_quicklink_leaderboard") 
        case "progress":
            WorkoutHistoryView() // Navigates to the view containing progress charts
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