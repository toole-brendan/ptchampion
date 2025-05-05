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
        ("Begin Push-Ups", "figure.strengthtraining.traditional", "workout-pushups"),
        ("Begin Sit-Ups", "figure.core", "workout-situps"),
        ("View Leaderboard", "list.star", "leaderboard"),
        ("Check Progress", "chart.line.uptrend.xyaxis", "progress")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Self.cardGap) {
                    // 4-1: Dynamic greeting with user's name
                    PTLabel("Good \(viewModel.timeOfDayGreeting), \(authViewModel.displayName)", style: .heading)
                        .padding(.bottom)
                    
                    // 4-2: Quick Stats Card Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: Self.cardGap),
                        GridItem(.flexible(), spacing: Self.cardGap)
                    ], spacing: Self.cardGap) {
                        MetricCard(label: "Last Score", value: viewModel.lastScoreString)
                        MetricCard(label: "7-Day Push-Ups", value: viewModel.weeklyReps)
                        MetricCard(label: "Monthly Workouts", value: viewModel.monthlyWorkouts)
                        MetricCard(label: "Personal Best", value: viewModel.personalBest)
                    }
                    
                    // 4-3: Primary Call-to-Action
                    NavigationLink(destination: WorkoutSelectionView()) {
                        HStack {
                            Spacer()
                            Text("Start Workout")
                                .font(AppTheme.GeneratedTypography.bodySemibold(size: AppTheme.GeneratedTypography.body))
                            Spacer()
                        }
                        .padding()
                        .background(AppTheme.GeneratedColors.brassGold)
                        .foregroundColor(AppTheme.GeneratedColors.cream)
                        .cornerRadius(AppTheme.GeneratedRadius.button)
                    }
                    .padding(.vertical, AppTheme.GeneratedSpacing.itemSpacing)
                    
                    // 4-4: Quick Links Section
                    PTLabel("Quick Links", style: .subheading)
                    
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
                        
                        PTCard {
                            HStack {
                                Text("🏅")
                                    .font(.title)
                                
                                VStack(alignment: .leading) {
                                    Text("Latest Achievement")
                                        .font(AppTheme.GeneratedTypography.bodySemibold(size: AppTheme.GeneratedTypography.body))
                                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                                    
                                    Text("Completed \(viewModel.weeklyReps) push-ups this week")
                                        .font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.small))
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

// Enhanced Metric Card with token-based styling
struct MetricCard: View {
    let label: String
    let value: String

    var body: some View {
        PTCard {
            VStack(alignment: .leading) {
                PTLabel(label, style: .caption)
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                
                PTLabel(value, style: .heading)
                    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityLabel("\(label): \(value)")
    }
}

// Quick Link Card component
struct QuickLinkCard: View {
    let title: String
    let icon: String
    let destination: String
    
    var body: some View {
        NavigationLink(destination: destinationView) {
            PTCard {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                        .frame(width: 30)
                    
                    Text(title)
                        .font(AppTheme.GeneratedTypography.bodySemibold(size: AppTheme.GeneratedTypography.small))
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        .padding(.leading, 4)
                    
                    Spacer()
                }
                .padding(AppTheme.GeneratedSpacing.itemSpacing)
            }
        }
    }
    
    // Determine the destination view based on the destination string
    @ViewBuilder
    private var destinationView: some View {
        // Simplified placeholder version to fix build errors
        Text("Navigating to: \(destination)...")
            .padding()
    }
}

#Preview {
    // Simple placeholder to fix build errors
    DashboardView()
        .environmentObject(AuthViewModel())
} 