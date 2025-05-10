import SwiftUI
import PTDesignSystem
import SwiftData
import Foundation

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
                        // Greeting header with user's name
                        greetingHeaderView()
                        
                        // Quick Stats Card Grid
                        quickStatsGridView()
                        
                        // Primary Call-to-Action - Now a static header
                        PTLabel("Start Workout", style: .heading)
                            .padding(.top, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Quick Links Section
                        quickLinksSectionView()

                        // Activity Feed Section
                        activityFeedSectionView()
                        
                        // Design Showcase Button (only in DEBUG builds)
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
            }
            .sheet(isPresented: $showingStyleShowcase) {
                MilitaryStyleShowcase()
            }
        }
    }
    
    // Helper method for the greeting header
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
    
    // Helper method for the quick stats grid
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

    // Helper method for the Quick Links section
    @ViewBuilder
    private func quickLinksSectionView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Use the same spacing pattern as the quickStatsGridView
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Self.cardGap),
                GridItem(.flexible(), spacing: Self.cardGap)
            ], spacing: Self.cardGap) {
                ForEach(quickLinks.indices, id: \.self) { index in
                    let link = quickLinks[index]
                    QuickLinkCardView(
                        title: link.title,
                        icon: link.icon,
                        destination: link.destination,
                        isSystemIcon: link.isSystemIcon
                    )
                    // Remove extra padding to match stat cards
                }
            }
            .opacity(quickLinksVisible ? 1 : 0)
            .offset(y: quickLinksVisible ? 0 : 15)
        }
    }
    
    // Helper method for the Activity Feed section
    @ViewBuilder
    private func activityFeedSectionView() -> some View {
        let activities = ActivityFeedSamples.items
        
        if !activities.isEmpty { // Show only if there are activities
            Group {
                Text("ACTIVITY FEED")
                    .militaryMonospaced(size: AppTheme.GeneratedTypography.small)
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    .padding(.top, AppTheme.GeneratedSpacing.large)
                    .padding(.bottom, AppTheme.GeneratedSpacing.small)
                
                PTSeparator().padding(.bottom, AppTheme.GeneratedSpacing.small)

                TimelineView(.periodic(from: Date(), by: 60.0)) { context in
                    let displayedActivities = Array(activities.prefix(3))
                    
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
                            PTSeparator(color: Color.gray.opacity(0.5))
                                .opacity(index < displayedActivities.count - 1 ? 1 : 0)
                        }
                    }
                    .padding(AppTheme.GeneratedSpacing.itemSpacing)
                    .background(AppTheme.GeneratedColors.cardBackground)
                    .cornerRadius(AppTheme.GeneratedRadius.medium)
                }
            }
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

#Preview {
    // Simple placeholder to fix build errors
    DashboardView()
        .environmentObject(AuthViewModel())
} 