import SwiftUI
import PTDesignSystem

/// A subview that contains the filter controls for the LeaderboardView
struct LeaderboardFilterBarView: View {
    @Binding var selectedCategory: LeaderboardCategory
    @Binding var selectedExercise: LeaderboardExerciseType
    @Binding var selectedRadius: LeaderboardRadius
    let showRadiusSelector: Bool
    
    var body: some View {
        VStack(spacing: AppTheme.GeneratedSpacing.medium) {
            // Filters section
            HStack(spacing: AppTheme.GeneratedSpacing.medium) {
                categoryFilterMenu
                exerciseFilterMenu
            }
            .padding(.horizontal)
            
            // Conditional Radius selector for Local leaderboards
            if showRadiusSelector {
                RadiusSelectorView(selectedRadius: $selectedRadius)
            }
        }
    }
    
    // Category filter (Daily, Weekly, etc.)
    private var categoryFilterMenu: some View {
        Menu {
            ForEach(LeaderboardCategory.allCases, id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                }) {
                    HStack {
                        Text(category.rawValue)
                        if selectedCategory == category {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            categoryFilterLabel
        }
        .tint(AppTheme.GeneratedColors.textPrimary)
    }
    
    private var categoryFilterLabel: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(AppTheme.GeneratedColors.primary)
            Text(selectedCategory.rawValue)
                .font(AppTheme.GeneratedTypography.body())
            Image(systemName: "chevron.down")
                .font(.caption)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.button)
                .fill(AppTheme.GeneratedColors.primary.opacity(0.1))
        )
    }
    
    // Exercise type filter
    private var exerciseFilterMenu: some View {
        Menu {
            ForEach(LeaderboardExerciseType.allCases, id: \.self) { exercise in
                Button(action: {
                    selectedExercise = exercise
                }) {
                    HStack {
                        Text(exercise.displayName)
                        if selectedExercise == exercise {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            exerciseFilterLabel
        }
        .tint(AppTheme.GeneratedColors.textPrimary)
    }
    
    private var exerciseFilterLabel: some View {
        HStack {
            Image(systemName: "figure.run")
                .foregroundColor(AppTheme.GeneratedColors.primary)
            Text(selectedExercise.displayName)
                .font(AppTheme.GeneratedTypography.body())
            Image(systemName: "chevron.down")
                .font(.caption)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.button)
                .fill(AppTheme.GeneratedColors.primary.opacity(0.1))
        )
    }
}

/// Radius selector component for the local leaderboard
struct RadiusSelectorView: View {
    @Binding var selectedRadius: LeaderboardRadius
    
    var body: some View {
        Menu {
            ForEach(LeaderboardRadius.allCases, id: \.self) { radius in
                Button {
                    selectedRadius = radius
                } label: {
                    Label(radius.displayName,
                          systemImage: selectedRadius == radius ? "checkmark" : "")
                }
            }
        } label: {
            HStack {
                Image(systemName: "map")
                    .foregroundColor(AppTheme.GeneratedColors.primary)
                Text("Radius: \(selectedRadius.displayName)")
                    .font(AppTheme.GeneratedTypography.body())
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.button)
                    .fill(AppTheme.GeneratedColors.primary.opacity(0.1))
            )
        }
        .tint(AppTheme.GeneratedColors.textPrimary)
        .padding(.horizontal)
    }
}

#if DEBUG
struct LeaderboardFilterBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            LeaderboardFilterBarView(
                selectedCategory: .constant(.weekly),
                selectedExercise: .constant(.pushup),
                selectedRadius: .constant(.five),
                showRadiusSelector: true
            )
            
            Divider()
            
            LeaderboardFilterBarView(
                selectedCategory: .constant(.monthly),
                selectedExercise: .constant(.overall),
                selectedRadius: .constant(.ten),
                showRadiusSelector: false
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif 