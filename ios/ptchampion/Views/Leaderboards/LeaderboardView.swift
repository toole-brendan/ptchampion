import SwiftUI
import CoreLocation // For CLAuthorizationStatus
import UIKit // For UIApplication
import os.log
import Combine
import PTDesignSystem
// Import shared views directly since they are not in separate modules
// import LeaderboardRow
// import LeaderboardRowPlaceholder

// Setup logger for this view
private let logger = Logger(subsystem: "com.ptchampion", category: "LeaderboardView")

struct LeaderboardView: View {
    // Add properties for viewModel and viewId
    @ObservedObject var viewModel: LeaderboardViewModel
    var viewId: String
    
    @State private var navigatingToUserID: String?
    @Namespace private var animation
    
    // Track active fetch task for cancellation
    @State private var fetchTask: Task<Void, Never>? = nil
    
    // Animation states for content
    @State private var segmentVisible = false
    @State private var filterVisible = false
    @State private var contentVisible = false
    
    // Haptic feedback generators
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    // Initialize with required parameters
    init(viewModel: LeaderboardViewModel, viewId: String) {
        self.viewModel = viewModel
        self.viewId = viewId
        // Use the new logging extension to prevent spam
        logDebug("Initialized LeaderboardView with ID: \(viewId)")
    }
    
    // Function to get formatted title - breaking up complex expression
    private var formattedFilterTitle: String {
        // Access properties individually to help compiler
        let exerciseName = viewModel.selectedExercise.displayName
        let timeframeName = viewModel.selectedCategory.rawValue
        // Now combine them
        return "\(exerciseName) • \(timeframeName)"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Ambient Background Gradient (matching Dashboard/WorkoutHistory)
                RadialGradient(
                    gradient: Gradient(colors: [
                        AppTheme.GeneratedColors.background.opacity(0.9),
                        AppTheme.GeneratedColors.background
                    ]),
                    center: .center,
                    startRadius: 50,
                    endRadius: UIScreen.main.bounds.height * 0.6
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                        // Custom styled header matching Dashboard/WorkoutHistory
                        VStack(spacing: 16) {
                            Text("\(viewModel.selectedBoard.rawValue.uppercased()) LEADERBOARD")
                                .font(.system(size: 32, weight: .bold))
                                .tracking(2)
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Rectangle()
                                .frame(width: 120, height: 1.5)
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(formattedFilterTitle.uppercased())
                                .font(.system(size: 16, weight: .regular))
                                .tracking(1.5)
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Filter controls section with animation
                        filterControlsSection
                            .opacity(segmentVisible ? 1 : 0)
                            .offset(y: segmentVisible ? 0 : 15)
                        
                        // Main leaderboard content in styled container
                        leaderboardContentSection
                            .opacity(contentVisible ? 1 : 0)
                            .offset(y: contentVisible ? 0 : 15)
                    }
                    .padding(AppTheme.GeneratedSpacing.contentPadding)
                }
                .refreshable {
                    impactFeedback.impactOccurred()
                    await viewModel.fetchWithDebouncing()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                animateContentIn()
                fetchTask = Task {
                    await viewModel.fetchWithDebouncing()
                }
            }
            .onDisappear {
                // Cancel any ongoing fetch when view disappears
                fetchTask?.cancel()
            }
            .onChange(of: viewModel.selectedBoard) { _ in
                selectionFeedback.selectionChanged()
                handleFilterChange()
            }
            .onChange(of: viewModel.selectedCategory) { _ in
                selectionFeedback.selectionChanged()
                handleFilterChange()
            }
            .onChange(of: viewModel.selectedExercise) { _ in
                selectionFeedback.selectionChanged()
                handleFilterChange()
            }
            .onChange(of: viewModel.selectedRadius) { _ in
                selectionFeedback.selectionChanged()
                handleFilterChange()
            }
            .navigationDestination(item: $navigatingToUserID) { userID in
                UserProfileView(userID: userID)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EmptyView()
                }
            }
        }
    }
    
    // MARK: - Filter Controls Section
    
    private var filterControlsSection: some View {
        VStack(spacing: AppTheme.GeneratedSpacing.medium) {
            // Styled segmented control matching ProfileView
            styledSegmentedControl
                .opacity(segmentVisible ? 1 : 0)
                .offset(y: segmentVisible ? 0 : 10)
            
            // Filter bar with consistent styling
            LeaderboardFilterBarView(
                selectedCategory: $viewModel.selectedCategory,
                selectedExercise: $viewModel.selectedExercise,
                selectedRadius: $viewModel.selectedRadius,
                showRadiusSelector: viewModel.selectedBoard == .local
            )
            .opacity(filterVisible ? 1 : 0)
            .offset(y: filterVisible ? 0 : 10)
        }
    }
    
    private var styledSegmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(LeaderboardType.allCases) { type in
                segmentButton(for: type)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 3,
                    x: 0,
                    y: 1
                )
        )
    }
    
    private func segmentButton(for type: LeaderboardType) -> some View {
        let isSelected = viewModel.selectedBoard == type
        
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.selectedBoard = type
            }
        }) {
            Text(type.rawValue.uppercased())
                .militaryMonospaced(size: 14)
                .foregroundColor(isSelected ? AppTheme.GeneratedColors.textOnPrimary : AppTheme.GeneratedColors.deepOps)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.GeneratedColors.deepOps)
                                .matchedGeometryEffect(id: "segmentBackground", in: animation)
                        }
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(type.rawValue) leaderboard")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
    
    // MARK: - Leaderboard Content Section
    
    private var leaderboardContentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header styled like Dashboard sections
            VStack(alignment: .leading, spacing: 4) {
                Text("TOP PERFORMERS")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                    .padding(.bottom, 4)
                
                Text(rankingsSubtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.GeneratedColors.deepOps)
            .cornerRadius(8, corners: [.topLeft, .topRight])
            
            // Content area with white background
            VStack {
                if viewModel.isLoading && viewModel.leaderboardEntries.isEmpty {
                    loadingContent
                } else if let errorMessage = viewModel.errorMessage {
                    errorContent(message: errorMessage)
                } else if viewModel.leaderboardEntries.isEmpty {
                    emptyStateContent
                } else {
                    leaderboardListContent
                }
            }
            .frame(minHeight: 300)
            .background(Color.white)
            .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var rankingsSubtitle: String {
        if viewModel.selectedBoard == .local {
            return "ATHLETES WITHIN \(viewModel.selectedRadius.rawValue) MILES"
        } else {
            return "NATIONWIDE RANKINGS"
        }
    }
    
    // MARK: - Content States
    
    private var loadingContent: some View {
        VStack(spacing: AppTheme.GeneratedSpacing.small) {
            ForEach(0..<5, id: \.self) { _ in
                EnhancedLeaderboardRowPlaceholder()
                    .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
    }
    
    private func errorContent(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 36))
                .foregroundColor(AppTheme.GeneratedColors.error)
                .padding()
                .background(
                    Circle()
                        .fill(AppTheme.GeneratedColors.error.opacity(0.1))
                        .frame(width: 80, height: 80)
                )
            
            Text("ERROR LOADING RANKINGS")
                .militaryMonospaced(size: 14)
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                .fontWeight(.medium)
            
            Text(message.uppercased())
                .militaryMonospaced(size: 12)
                .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            PTButton("RETRY", style: PTButton.ButtonStyle.primary, action: {
                impactFeedback.impactOccurred()
                Task { await viewModel.fetchWithDebouncing() }
            })
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error loading rankings. \(message)")
        .accessibilityHint("Double tap retry button to reload")
    }
    
    private var emptyStateContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 36))
                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                .padding()
                .background(
                    Circle()
                        .fill(AppTheme.GeneratedColors.brassGold.opacity(0.1))
                        .frame(width: 80, height: 80)
                )
            
            Text(viewModel.backendStatus == .noActiveUsers ? "NO ACTIVE ATHLETES" : "NO RANKINGS YET")
                .militaryMonospaced(size: 14)
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                .fontWeight(.medium)
            
            Text(viewModel.backendStatus == .noActiveUsers ? 
                 "BE THE FIRST TO POST A SCORE" : 
                 "COMPLETE A WORKOUT TO APPEAR HERE")
                .militaryMonospaced(size: 12)
                .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.backendStatus == .noActiveUsers ? 
                          "No active athletes. Be the first to post a score" : 
                          "No rankings yet. Complete a workout to appear here")
    }
    
    private var leaderboardListContent: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.leaderboardEntries.enumerated()), id: \.element.id) { index, entry in
                let isCurrentUser = entry.userId == viewModel.currentUserID && entry.userId != nil
                
                VStack(spacing: 0) {
                    EnhancedLeaderboardRow(
                        entry: entry,
                        isCurrentUser: isCurrentUser,
                        rank: index + 1
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleRowTap(entry: entry)
                    }
                    
                    if index < viewModel.leaderboardEntries.count - 1 {
                        Divider()
                            .background(Color.gray.opacity(0.2))
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Helper Methods
    
    private func handleFilterChange() {
        fetchTask?.cancel()
        
        withAnimation {
            viewModel.leaderboardEntries = []
            viewModel.isLoading = true
        }
        
        fetchTask = Task {
            await viewModel.fetchWithDebouncing()
        }
    }
    
    private func handleRowTap(entry: LeaderboardEntryView) {
        if let userID = entry.userId {
            impactFeedback.impactOccurred()
            logger.info("Tapping user: \(entry.name, privacy: .public), ID: \(userID, privacy: .public)")
            self.navigatingToUserID = userID
        }
    }
    
    private func animateContentIn() {
        segmentVisible = false
        filterVisible = false
        contentVisible = false
        
        let baseDelay = 0.1
        let staggerDelay = 0.1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + baseDelay) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                segmentVisible = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + baseDelay + staggerDelay) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                filterVisible = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + baseDelay + (staggerDelay * 2)) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                contentVisible = true
            }
        }
    }
}

// MARK: - Enhanced Leaderboard Row Component

struct EnhancedLeaderboardRow: View {
    let entry: LeaderboardEntryView
    let isCurrentUser: Bool
    let rank: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Enhanced rank badge with proper medal colors
            ZStack {
                Circle()
                    .fill(rankBackgroundColor)
                    .frame(width: 44, height: 44)
                
                if rank <= 3 {
                    Image(systemName: rankIcon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(rankIconColor)
                } else {
                    Text("\(rank)")
                        .militaryMonospaced(size: 16)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                }
            }
            
            // User info with performance indicators
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(entry.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        .lineLimit(1)
                    
                    // Performance indicator (if available)
                    if let change = entry.performanceChange {
                        performanceIndicator(change)
                    }
                    
                    // Personal best indicator (if available)
                    if entry.isPersonalBest == true {
                        personalBestBadge
                    }
                }
                
                if entry.locationDescription != nil || entry.unit != nil {
                    HStack(spacing: 4) {
                        if let unit = entry.unit {
                            Text(unit)
                                .militaryMonospaced(size: 12)
                                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        }
                        if entry.unit != nil && entry.locationDescription != nil {
                            Text("•")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        }
                        if let location = entry.locationDescription {
                            Text(location)
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Score/metric with enhanced styling
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.displayValue)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(scoreColor)
                
                if let subtitle = entry.displaySubtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            isCurrentUser ? 
            AppTheme.GeneratedColors.brassGold.opacity(0.05) : 
            Color.clear
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(entry.userId != nil ? "Double tap to view profile" : "")
        .accessibilityAddTraits(entry.userId != nil ? .isButton : [])
    }
    
    // MARK: - Helper Views
    
    private func performanceIndicator(_ change: PerformanceChange) -> some View {
        Image(systemName: change.icon)
            .font(.system(size: 12))
            .foregroundColor(change.color)
    }
    
    private var personalBestBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.system(size: 8))
            Text("PB")
                .militaryMonospaced(size: 8)
                .fontWeight(.bold)
        }
        .foregroundColor(AppTheme.GeneratedColors.brassGold)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(AppTheme.GeneratedColors.brassGold.opacity(0.2))
        )
    }
    
    // MARK: - Computed Properties
    
    private var rankBackgroundColor: Color {
        switch rank {
        case 1: return goldColor.opacity(0.2)
        case 2: return silverColor.opacity(0.2)
        case 3: return bronzeColor.opacity(0.2)
        default: return AppTheme.GeneratedColors.oliveMist.opacity(0.2)
        }
    }
    
    private var rankIcon: String {
        switch rank {
        case 1: return "trophy.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return ""
        }
    }
    
    private var rankIconColor: Color {
        switch rank {
        case 1: return goldColor
        case 2: return silverColor
        case 3: return bronzeColor
        default: return AppTheme.GeneratedColors.deepOps
        }
    }
    
    private var scoreColor: Color {
        switch rank {
        case 1: return goldColor
        case 2: return silverColor
        case 3: return bronzeColor
        default: return AppTheme.GeneratedColors.brassGold
        }
    }
    
    private var goldColor: Color {
        Color(red: 1.0, green: 0.84, blue: 0.0) // #FFD700
    }
    
    private var silverColor: Color {
        Color(red: 0.75, green: 0.75, blue: 0.75) // #C0C0C0
    }
    
    private var bronzeColor: Color {
        Color(red: 0.8, green: 0.5, blue: 0.2) // #CD7F32
    }
    
    private var accessibilityLabel: String {
        var label = "\(entry.name), ranked \(rank)"
        
        switch rank {
        case 1: label += ", gold medal"
        case 2: label += ", silver medal" 
        case 3: label += ", bronze medal"
        default: break
        }
        
        label += ", score \(entry.displayValue)"
        
        if entry.isPersonalBest == true {
            label += ", personal best"
        }
        
        if let change = entry.performanceChange {
            switch change {
            case .improved(let positions):
                label += ", improved \(positions) positions"
            case .declined(let positions):
                label += ", declined \(positions) positions"
            case .maintained:
                label += ", maintained position"
            }
        }
        
        return label
    }
}

// MARK: - Enhanced Loading Placeholder with Shimmer

struct EnhancedLeaderboardRowPlaceholder: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank placeholder
            Circle()
                .fill(shimmerGradient)
                .frame(width: 44, height: 44)
            
            // Name and info placeholder
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 120, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 80, height: 12)
            }
            
            Spacer()
            
            // Score placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(shimmerGradient)
                .frame(width: 60, height: 20)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
    
    private var shimmerGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.gray.opacity(0.3),
                Color.gray.opacity(0.1),
                Color.gray.opacity(0.3)
            ]),
            startPoint: isAnimating ? .leading : .trailing,
            endPoint: isAnimating ? .trailing : .leading
        )
    }
}

// MARK: - Performance Change Extension

extension PerformanceChange {
    var color: Color {
        switch self {
        case .improved: return AppTheme.GeneratedColors.success
        case .declined: return AppTheme.GeneratedColors.error
        case .maintained: return AppTheme.GeneratedColors.textSecondary
        }
    }
}

// MARK: - Helper Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

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

#Preview {
    // For preview to work with .navigationDestination, it might need to be in a NavigationStack here too
    NavigationStack {
        LeaderboardView(
            viewModel: LeaderboardViewModel(),
            viewId: "PREVIEW"
        )
    }
}

#Preview("Local Mode") {
    // Create the model, set the board to .local
    let vm = LeaderboardViewModel()
    vm.selectedBoard = .local

    // Pass the prepared model into the view
    return NavigationStack {
        LeaderboardView(
            viewModel: vm,
            viewId: "LOCAL-PREVIEW"
        )
    }
} 