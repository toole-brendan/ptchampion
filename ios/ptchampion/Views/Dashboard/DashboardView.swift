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
    
    // Enum for rubric modals (identifiable for sheet)
    private enum RubricType: String, Identifiable {
        case pushups, situps, pullups, running
        var id: String { self.rawValue }
    }
    
    @State private var activeRubric: RubricType? = nil
    
    // Quick links for navigation
    private let quickLinks: [(title: String, icon: String, destination: String, isSystemIcon: Bool)] = [
        ("Push-Ups", "pushup", "workout-pushups", false),
        ("Sit-Ups", "situp", "workout-situps", false),
        ("Pull-Ups", "pullup", "workout-pullups", false),
        ("Running", "running", "workout-running", false)
    ]
    
    // Rubric options for scoring criteria
    private let rubricOptions: [(title: String, icon: String, type: RubricType, isSystemIcon: Bool)] = [
        ("Push-Ups", "pushup", .pushups, false),
        ("Sit-Ups", "situp", .situps, false),
        ("Pull-Ups", "pullup", .pullups, false),
        ("Running", "running", .running, false)
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
                        // PT Champion header with separator
                        VStack(spacing: 24) {
                            Text("PT CHAMPION")
                                .font(.system(size: 48, weight: .heavy))
                                .tracking(2) // Add letter spacing
                                .foregroundColor(Color(hex: "#C0A860")) // More accurate gold color
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            Rectangle()
                                .frame(width: 120, height: 1.5)
                                .foregroundColor(Color(hex: "#C0A860"))
                            
                            Text("FITNESS EVALUATION SYSTEM")
                                .font(.system(size: 18, weight: .regular))
                                .tracking(1.5) // Add letter spacing
                                .foregroundColor(Color(hex: "#4A4A3A"))
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 30)
                        .frame(maxWidth: .infinity)
                        
                        // Quick Links Section with the new styling
                        quickLinksSectionView()
                        
                        // Scoring Rubric Section
                        scoringRubricSectionView()
                        
                        // Greeting header with user's name and stats
                        greetingHeaderView()
                        
                        // Activity Feed Section
                        activityFeedSectionView()
                        
                        // Design Showcase Button (only in DEBUG builds)
                        #if DEBUG
                        // Removed Military UI Showcase button while keeping the DEBUG conditional for future use
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
            .sheet(item: $activeRubric) { rubric in
                switch rubric {
                case .pushups:
                    PushUpsRubricView()
                case .situps:
                    SitUpsRubricView()
                case .pullups:
                    PullUpsRubricView()
                case .running:
                    RunningRubricView()
                }
            }
        }
    }
    
    // Helper method for the greeting header
    @ViewBuilder
    private func greetingHeaderView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header matching START TRACKING section with dark background and gold text
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center) {
                    Text(authViewModel.displayName.uppercased())
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    
                    Spacer()
                    
                    // View Profile button
                    NavigationLink(destination: ProfileView()) {
                        HStack(spacing: 8) {
                            Text("VIEW PROFILE")
                                .font(.system(size: 14, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(AppTheme.GeneratedColors.brassGold, lineWidth: 1)
                        )
                    }
                }
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                    .padding(.bottom, 4)
                
                Text("\(viewModel.totalWorkouts) TOTAL WORKOUTS COMPLETED")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppTheme.GeneratedColors.deepOps)
            .cornerRadius(8, corners: [.topLeft, .topRight])
            
            // Profile stats in light background similar to quick links
            VStack(spacing: 16) {
                // Stats cards in a grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    // Total Workouts
                    statCardStyled(
                        title: "TOTAL WORKOUTS",
                        value: "\(viewModel.totalWorkouts)",
                        iconName: "flame.fill",
                        index: 0
                    )
                    
                    // Last Activity
                    statCardStyled(
                        title: "LAST ACTIVITY",
                        value: viewModel.lastWorkoutDate != nil ? viewModel.lastWorkoutDateFormatted : "None",
                        subtitle: viewModel.lastWorkoutDate == nil ? "No workouts yet" : nil,
                        iconName: "calendar",
                        index: 1
                    )
                    
                    // Total Repetitions
                    statCardStyled(
                        title: "TOTAL REPETITIONS",
                        value: "\(viewModel.totalReps) reps",
                        iconName: "arrow.up.arrow.down",
                        index: 2
                    )
                    
                    // Total Distance
                    statCardStyled(
                        title: "TOTAL DISTANCE",
                        value: String(format: "%.1f km", viewModel.totalDistanceKm),
                        iconName: "figure.walk",
                        index: 3
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(hex: "#EDE9DB")) // cream-dark from web
            .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.bottom, AppTheme.GeneratedSpacing.medium)
    }
    
    // Helper method for styled stat cards that look like QuickLinkCardView
    @ViewBuilder
    private func statCardStyled(title: String, value: String, subtitle: String? = nil, iconName: String, index: Int) -> some View {
        NavigationLink {
            if title == "TOTAL WORKOUTS" || title == "TOTAL REPETITIONS" {
                // Navigate to history with all workouts
                WorkoutHistoryView()
            } else if title == "LAST ACTIVITY" {
                // Navigate to history with all workouts
                WorkoutHistoryView()
            } else if title == "TOTAL DISTANCE" {
                // Navigate to history filtered to running workouts
                WorkoutHistoryView(initialFilterType: .run)
            } else {
                // Default case
                WorkoutHistoryView()
            }
        } label: {
            VStack(alignment: .center, spacing: 12) {
                // Icon centered in circle container
                ZStack {
                    Circle()
                        .fill(AppTheme.GeneratedColors.oliveMist.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                }
                
                // Stat value with title
                VStack(spacing: 2) {
                    Text(value)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    
                    Text(title)
                        .militaryMonospaced(size: 12)
                        .foregroundColor(AppTheme.GeneratedColors.deepOps.opacity(0.8))
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 3,
                x: 0,
                y: 1
            )
            .opacity(index < statCardsVisible.count ? (statCardsVisible[index] ? 1 : 0) : 1)
            .offset(y: index < statCardsVisible.count ? (statCardsVisible[index] ? 0 : 15) : 0)
        }
        .buttonStyle(PlainButtonStyle()) // Use plain button style to maintain custom appearance
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
    
    // Scoring Rubric Section
    @ViewBuilder
    private func scoringRubricSectionView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (dark background with gold text)
            VStack(alignment: .leading, spacing: 4) {
                Text("SCORING RUBRIC")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                    .padding(.bottom, 4)
                
                Text("VIEW SCORING CRITERIA FOR EACH EXERCISE")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.GeneratedColors.deepOps)
            .cornerRadius(8, corners: [.topLeft, .topRight])
            
            // Vertical list of exercises with arrows
            VStack(alignment: .leading, spacing: 8) {
                ForEach(rubricOptions, id: \.title) { option in
                    Button(action: {
                        // Open the corresponding rubric modal
                        activeRubric = option.type
                    }) {
                        HStack {
                            // Exercise name
                            Text(option.title.uppercased())
                                .militaryMonospaced(size: 16)
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                            
                            Spacer()
                            
                            // Right arrow
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(Color.white)
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Color(hex: "#EDE9DB"))
            .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // Helper method for the Activity Feed section
    @ViewBuilder
    private func activityFeedSectionView() -> some View {
        if !viewModel.recentWorkouts.isEmpty { // Show only if there are activities
            VStack(alignment: .leading, spacing: 0) {
                // Header matching other sections - dark background with gold text
                VStack(alignment: .leading, spacing: 4) {
                    Text("RECENT ACTIVITY")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                        .padding(.bottom, 4)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                        .padding(.bottom, 4)
                    
                    Text("YOUR LATEST WORKOUT SESSIONS")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.GeneratedColors.deepOps)
                .cornerRadius(8, corners: [.topLeft, .topRight])
                
                // Activity content with cream background
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.recentWorkouts) { workout in
                        NavigationLink(destination: WorkoutHistoryView(initialFilterType: getFilterType(for: workout.exerciseType))) {
                            HStack { 
                                // Exercise icon in circular container
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.GeneratedColors.brassGold.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: iconForExerciseType(workout.exerciseType))
                                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                        .frame(width: 20, height: 20)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(formatExerciseType(workout.exerciseType))
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                        .lineLimit(2)
                                    
                                    Text(relativeDateFormatter(date: workout.endTime))
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer() 
                                
                                // Activity metric (like distance or reps)
                                Text(formatWorkoutMetric(workout))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 0)
                                    .fill(Color.clear)
                                    .contentShape(Rectangle())
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if workout.id != viewModel.recentWorkouts.last?.id {
                            Divider()
                                .background(Color.gray.opacity(0.2))
                                .padding(.horizontal, 16)
                        }
                    }
                    
                    // View All button
                    NavigationLink(destination: WorkoutHistoryView()) {
                        HStack {
                            Spacer()
                            
                            Text("VIEW DETAILED HISTORY")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                            
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(AppTheme.GeneratedColors.brassGold.opacity(0.1))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .background(Color(hex: "#EDE9DB")) // cream-dark from web
                .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
            }
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            .opacity(recentActivityVisible ? 1 : 0)
            .offset(y: recentActivityVisible ? 0 : 15)
        } else {
            // Empty state with "No workouts yet" message
            VStack(alignment: .leading, spacing: 0) {
                // Header matching other sections
                VStack(alignment: .leading, spacing: 4) {
                    Text("RECENT ACTIVITY")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                        .padding(.bottom, 4)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                        .padding(.bottom, 4)
                    
                    Text("YOUR LATEST WORKOUT SESSIONS")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.GeneratedColors.deepOps)
                .cornerRadius(8, corners: [.topLeft, .topRight])
                
                // Empty state content
                VStack(spacing: 20) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                        .padding()
                        .background(
                            Circle()
                                .fill(AppTheme.GeneratedColors.brassGold.opacity(0.1))
                                .frame(width: 80, height: 80)
                        )
                    
                    Text("No Workouts Yet")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    
                    Text("Start your fitness journey by completing your first workout.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    NavigationLink(destination: WorkoutSessionView(exerciseType: .pushup)) {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                            Text("START WORKOUT")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(AppTheme.GeneratedColors.textOnPrimary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppTheme.GeneratedColors.brassGold)
                        .cornerRadius(8)
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
                .background(Color(hex: "#EDE9DB")) // cream-dark from web
                .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
            }
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            .opacity(recentActivityVisible ? 1 : 0)
            .offset(y: recentActivityVisible ? 0 : 15)
        }
    }
    
    // Helper function to convert exercise type to filter type
    private func getFilterType(for exerciseType: String) -> WorkoutFilter {
        switch exerciseType.lowercased() {
        case "pushup":
            return .pushup
        case "situp":
            return .situp
        case "pullup":
            return .pullup
        case "run", "running":
            return .run
        default:
            return .all
        }
    }
    
    // Helper function to format exercise type for display
    private func formatExerciseType(_ type: String) -> String {
        switch type.lowercased() {
        case "pushup":
            return "Push-ups"
        case "situp":
            return "Sit-ups"
        case "pullup":
            return "Pull-ups"
        case "run", "running":
            return "Running"
        default:
            return type.capitalized
        }
    }
    
    // Helper function to get icon for exercise type
    private func iconForExerciseType(_ type: String) -> String {
        switch type.lowercased() {
        case "pushup":
            return "figure.strengthtraining.traditional"
        case "situp":
            return "figure.core.training"
        case "pullup":
            return "figure.pull.ups"
        case "run", "running":
            return "figure.run"
        default:
            return "figure.mixed.cardio"
        }
    }
    
    // Helper function to format workout metric (reps or distance)
    private func formatWorkoutMetric(_ workout: WorkoutResultSwiftData) -> String {
        if workout.exerciseType.lowercased() == "run" || workout.exerciseType.lowercased() == "running" {
            if let distance = workout.distanceMeters {
                return String(format: "%.1f km", distance / 1000.0)
            }
            return "-"
        } else {
            if let reps = workout.repCount {
                return "\(reps) reps"
            }
            return "-"
        }
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