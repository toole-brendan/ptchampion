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
    
    // Quick links for navigation
    private let quickLinks: [(title: String, icon: String, destination: String, isSystemIcon: Bool)] = [
        ("Begin Push-Ups", "pushup", "workout-pushups", false),
        ("Begin Sit-Ups", "situp", "workout-situps", false),
        ("View Leaderboard", "list.star", "leaderboard", true),
        ("Check Progress", "chart.line.uptrend.xyaxis", "progress", true)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Self.cardGap) {
                    // 4-1: Dynamic greeting with user's name
                    HStack(spacing: 0) {
                        Text("Good \(viewModel.timeOfDayGreeting), ")
                        Text(authViewModel.displayName)
                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    }
                    .font(.system(size: AppTheme.GeneratedTypography.heading2, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom)
                    
                    // 4-2: Quick Stats Card Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: Self.cardGap),
                        GridItem(.flexible(), spacing: Self.cardGap)
                    ], spacing: Self.cardGap) {
                        MetricCardView(
                            MetricData(
                                title: "Last Score",
                                value: viewModel.lastScoreString
                            ),
                            trend: viewModel.lastScoreTrend
                        )
                        MetricCardView(
                            MetricData(
                                title: "7-Day Push-Ups",
                                value: viewModel.weeklyReps
                            ),
                            trend: viewModel.weeklyPushupTrend
                        )
                        MetricCardView(
                            MetricData(
                                title: "Monthly Workouts",
                                value: viewModel.monthlyWorkouts
                            )
                        )
                        MetricCardView(
                            MetricData(
                                title: "Personal Best",
                                value: viewModel.personalBest
                            )
                        )
                    }
                    
                    // 4-3: Primary Call-to-Action
                    NavigationLink(destination: WorkoutSelectionView()) {
                        PTButton("Start Workout") {
                            // action
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle()) // Remove NavigationLink styling
                    .padding(.vertical, AppTheme.GeneratedSpacing.itemSpacing)
                    
                    // 4-4: Quick Links Section
                    PTLabel("Quick Links", style: .subheading)
                    PTSeparator().padding(.bottom, AppTheme.GeneratedSpacing.small)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: Self.cardGap),
                        GridItem(.flexible(), spacing: Self.cardGap)
                    ], spacing: Self.cardGap) {
                        ForEach(quickLinks, id: \.title) { link in
                            QuickLinkCard(title: link.title, icon: link.icon, destination: link.destination, isSystemIcon: link.isSystemIcon)
                        }
                    }
                    
                    // 4-5: Activity Feed (Optional)
                    if viewModel.totalWorkouts > 0 {
                        PTLabel("Recent Activity", style: .subheading)
                            .padding(.top)
                        PTSeparator().padding(.bottom, AppTheme.GeneratedSpacing.small)
                        
                        PTCard {
                            HStack {
                                PTLabel("🏅", style: .heading)
                                
                                VStack(alignment: .leading) {
                                    PTLabel("Latest Achievement", style: .bodyBold)
                                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                                    
                                    PTLabel("Completed \(viewModel.weeklyReps) push-ups this week", style: .body)
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding(AppTheme.GeneratedSpacing.itemSpacing)
                        }
                        .transition(.move(edge: .top))
                    }
                    
                    Spacer()
                }
                .padding(Self.globalPadding)
            }
            .refreshable {
                viewModel.refresh()
            }
            .background(AppTheme.GeneratedColors.background.ignoresSafeArea())
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityLabel("You have \(viewModel.totalWorkouts) workouts logged")
            .onAppear {
                viewModel.setModelContext(modelContext)
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