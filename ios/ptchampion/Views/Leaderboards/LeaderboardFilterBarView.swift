import SwiftUI
import PTDesignSystem

/// A subview that contains the filter controls for the LeaderboardView
struct LeaderboardFilterBarView: View {
    @Binding var selectedCategory: LeaderboardCategory
    @Binding var selectedExercise: LeaderboardExerciseType
    @Binding var selectedRadius: LeaderboardRadius
    let showRadiusSelector: Bool
    
    var body: some View {
        VStack(spacing: Spacing.medium) {
            // Filters section
            HStack(spacing: Spacing.medium) {
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
        .tint(Color.textPrimary)
    }
    
    private var categoryFilterLabel: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(Color.primary)
            Text(selectedCategory.rawValue)
                .body()
            Image(systemName: "chevron.down")
                .caption()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.button)
                .fill(Color.primary.opacity(0.1)
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
        .tint(Color.textPrimary)
    }
    
    private var exerciseFilterLabel: some View {
        HStack {
            Image(systemName: "figure.run")
                .foregroundColor(Color.primary)
            Text(selectedExercise.displayName)
                .body()
            Image(systemName: "chevron.down")
                .caption()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.button)
                .fill(Color.primary.opacity(0.1)
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
                    .foregroundColor(Color.primary)
                Text("Radius: \(selectedRadius.displayName)")
                    .body()
                Image(systemName: "chevron.down")
                    .caption()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.button)
                    .fill(Color.primary.opacity(0.1)
            )
        }
        .tint(Color.textPrimary)
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