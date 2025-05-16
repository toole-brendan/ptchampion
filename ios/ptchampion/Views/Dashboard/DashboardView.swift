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
                        
                        // Quick Links Section with the new styling
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
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("Good \(viewModel.timeOfDayGreeting),")
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            Text(authViewModel.displayName)
                .lineLimit(1)
                .truncationMode(.tail)
                .minimumScaleFactor(0.7)
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
                .frame(maxWidth: .infinity, alignment: .center)
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
            // Header matching web version - dark background with gold text
            VStack(alignment: .leading, spacing: 4) {
                Text("START TRACKING")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                    .padding(.bottom, 4)
                
                Text("CHOOSE AN EXERCISE TO BEGIN A NEW SESSION")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.GeneratedColors.deepOps)
            .cornerRadius(8, corners: [.topLeft, .topRight])
            
            // Cards grid with light background
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(quickLinks.indices, id: \.self) { index in
                    let link = quickLinks[index]
                    QuickLinkCardView(
                        title: link.title,
                        icon: link.icon,
                        destination: link.destination,
                        isSystemIcon: link.isSystemIcon
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(hex: "#EDE9DB")) // cream-dark from web
            .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
            .opacity(quickLinksVisible ? 1 : 0)
            .offset(y: quickLinksVisible ? 0 : 15)
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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

// Helper for rounded corners on specific sides
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// Custom shape for rounded corners
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Helper for hex color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 