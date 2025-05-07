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
    private let quickLinks: [(title: String, icon: String, destination: String)] = [
        ("Begin Push-Ups", "pushup", "workout-pushups"),
        ("Begin Sit-Ups", "situp", "workout-situps"),
        ("View Leaderboard", "list.star", "leaderboard"),
        ("Check Progress", "chart.line.uptrend.xyaxis", "progress")
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
                            QuickLinkCard(title: link.title, icon: link.icon, destination: link.destination)
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
    
    // For haptics
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        NavigationLink(destination: destinationView) {
            PTCard {
                HStack(alignment: .center) {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                        .frame(width: 24, height: 24)
                    
                    PTLabel(title, style: .body)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        .padding(.leading, AppTheme.GeneratedSpacing.extraSmall)
                    
                    Spacer()
                }
                .padding(AppTheme.GeneratedSpacing.itemSpacing)
                .frame(minHeight: 60)
            }
        }
        .onTapGesture {
            hapticGenerator.impactOccurred()
        }
    }
    
    // Determine the destination view based on the destination string
    @ViewBuilder
    private var destinationView: some View {
        // Simplified placeholder version to fix build errors
        PTLabel("Navigating to: \(destination)...", style: .body)
            .padding()
    }
}

#Preview {
    // Simple placeholder to fix build errors
    DashboardView()
        .environmentObject(AuthViewModel())
} 