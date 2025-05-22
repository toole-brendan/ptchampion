import SwiftUI
import PTDesignSystem

/// A subview that contains the filter controls for the LeaderboardView
struct LeaderboardFilterBarView: View {
    @Binding var selectedCategory: LeaderboardCategory
    @Binding var selectedExercise: LeaderboardExerciseType
    @Binding var selectedRadius: LeaderboardRadius
    let showRadiusSelector: Bool
    
    // Animation states
    @State private var filtersVisible = false
    @Namespace private var filterAnimation
    
    var body: some View {
        VStack(spacing: AppTheme.GeneratedSpacing.medium) {
            // Exercise type filter with updated styling
            exerciseFilterSection
            
            // Time period and radius filters
            HStack(spacing: AppTheme.GeneratedSpacing.medium) {
                // Time period filter
                timePeriodFilter
                
                // Radius filter (only for local)
                if showRadiusSelector {
                    radiusFilter
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.2)) {
                filtersVisible = true
            }
        }
    }
    
    // MARK: - Exercise Filter Section
    
    private var exerciseFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.GeneratedSpacing.small) {
                ForEach(LeaderboardExerciseType.allCases) { exercise in
                    exerciseButton(for: exercise)
                }
            }
            .padding(.horizontal, 2)
        }
        .opacity(filtersVisible ? 1 : 0)
        .offset(y: filtersVisible ? 0 : 10)
    }
    
    private func exerciseButton(for exercise: LeaderboardExerciseType) -> some View {
        let isSelected = selectedExercise == exercise
        
        return Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedExercise = exercise
            }
        }) {
            HStack(spacing: 8) {
                // Exercise icon
                Image(systemName: exerciseIcon(for: exercise))
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? AppTheme.GeneratedColors.brassGold : AppTheme.GeneratedColors.deepOps)
                
                // Exercise name
                Text(exercise.displayName.uppercased())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(isSelected ? AppTheme.GeneratedColors.brassGold : AppTheme.GeneratedColors.deepOps)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.GeneratedColors.deepOps)
                            .matchedGeometryEffect(id: "exerciseBackground", in: filterAnimation)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppTheme.GeneratedColors.deepOps.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            )
            .shadow(
                color: isSelected ? Color.black.opacity(0.1) : Color.black.opacity(0.05),
                radius: isSelected ? 4 : 2,
                x: 0,
                y: isSelected ? 2 : 1
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Time Period Filter
    
    private var timePeriodFilter: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TIME PERIOD")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                .tracking(1)
            
            Menu {
                ForEach(LeaderboardCategory.allCases) { category in
                    Button(action: {
                        withAnimation {
                            selectedCategory = category
                        }
                    }) {
                        HStack {
                            Text(category.rawValue.uppercased())
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                            
                            if selectedCategory == category {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedCategory.rawValue.uppercased())
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.GeneratedColors.deepOps.opacity(0.3), lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 2,
                    x: 0,
                    y: 1
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Radius Filter
    
    private var radiusFilter: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("RADIUS")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                .tracking(1)
            
            Menu {
                ForEach(LeaderboardRadius.allCases) { radius in
                    Button(action: {
                        withAnimation {
                            selectedRadius = radius
                        }
                    }) {
                        HStack {
                            Text(radius.displayName.uppercased())
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                            
                            if selectedRadius == radius {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedRadius.displayName.uppercased())
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.GeneratedColors.deepOps.opacity(0.3), lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 2,
                    x: 0,
                    y: 1
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Functions
    
    private func exerciseIcon(for exercise: LeaderboardExerciseType) -> String {
        switch exercise {
        case .overall:
            return "star.fill"
        case .pushup:
            return "figure.strengthtraining.traditional"
        case .situp:
            return "figure.core.training"
        case .pullup:
            return "figure.mixed.cardio"
        case .running:
            return "figure.run"
        }
    }
}



#if DEBUG
struct LeaderboardFilterBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            LeaderboardFilterBarView(
                selectedCategory: .constant(.weekly),
                selectedExercise: .constant(.pushup),
                selectedRadius: .constant(.ten),
                showRadiusSelector: true
            )
            .padding()
            
            Divider()
            
            LeaderboardFilterBarView(
                selectedCategory: .constant(.monthly),
                selectedExercise: .constant(.overall),
                selectedRadius: .constant(.twentyFive),
                showRadiusSelector: false
            )
            .padding()
        }
        .background(AppTheme.GeneratedColors.background)
        .previewLayout(.sizeThatFits)
    }
}
#endif 