import SwiftUI
import PTDesignSystem

struct WorkoutSelectionView: View {
    @EnvironmentObject var tabBarVisibility: TabBarVisibilityManager
    
    // Use ExerciseType directly instead of custom Exercise struct
    let exercises: [(exercise: ExerciseType, description: String, color: Color)] = [
        (.pushup, "Upper body strength training focusing on chest, shoulders, and triceps", AppTheme.GeneratedColors.brassGold),
        (.situp, "Core strength exercise targeting abdominal muscles", AppTheme.GeneratedColors.deepOps),
        (.pullup, "Upper body exercise focusing on back, shoulders, and arms", AppTheme.GeneratedColors.primary),
        (.run, "Cardiovascular training for endurance and stamina", AppTheme.GeneratedColors.success)
    ]
    
    // For staggered animations
    @State private var cardsVisible = [false, false, false, false]
    @State private var headerVisible = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                // Motivational header
                motivationalHeader
                    .opacity(headerVisible ? 1 : 0)
                    .offset(y: headerVisible ? 0 : -20)
                
                // Exercise cards
                exerciseCards
            }
            .padding(AppTheme.GeneratedSpacing.contentPadding)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    AppTheme.GeneratedColors.background,
                    AppTheme.GeneratedColors.background.opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
        )
        .navigationTitle("Choose Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar(!tabBarVisibility.isTabBarVisible)
        .onAppear {
            tabBarVisibility.hideTabBar()
            animateContent()
        }
        .onDisappear {
            tabBarVisibility.showTabBar()
        }
    }
    
    // MARK: - View Components
    
    private var motivationalHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
            Text("Ready for a Challenge?")
                .font(.title.weight(.bold))
                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
            
            Text("Select an exercise to begin your workout session")
                .font(.subheadline)
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, AppTheme.GeneratedSpacing.medium)
    }
    
    private var exerciseCards: some View {
        VStack(spacing: AppTheme.GeneratedSpacing.medium) {
            ForEach(Array(exercises.enumerated()), id: \.offset) { index, exerciseData in
                ExerciseCard(
                    exercise: exerciseData.exercise,
                    description: exerciseData.description,
                    color: exerciseData.color,
                    destination: {
                        if exerciseData.exercise == .run {
                            return AnyView(RunWorkoutView())
                        } else {
                            return AnyView(WorkoutSessionView(exerciseType: exerciseData.exercise))
                        }
                    }
                )
                .opacity(cardsVisible[index] ? 1 : 0)
                .offset(y: cardsVisible[index] ? 0 : 20)
            }
        }
    }
    
    // MARK: - Animations
    
    private func animateContent() {
        // Reset states for re-animation if view appears again
        cardsVisible = [false, false, false, false]
        headerVisible = false
        
        // Animate header first
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
            headerVisible = true
        }
        
        // Stagger the card animations
        for i in 0..<cardsVisible.count {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3 + Double(i) * 0.1)) {
                cardsVisible[i] = true
            }
        }
    }
}

// MARK: - Exercise Card Component

struct ExerciseCard: View {
    let exercise: ExerciseType
    let description: String
    let color: Color
    let destination: () -> AnyView
    
    @State private var isPressed = false
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: AppTheme.GeneratedSpacing.medium) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: exercise.icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                
                // Exercise info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.displayName)
                        .font(.headline)
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundColor(AppTheme.GeneratedColors.textTertiary)
            }
            .padding(AppTheme.GeneratedSpacing.medium)
            .background(AppTheme.GeneratedColors.cardBackground)
            .cornerRadius(AppTheme.GeneratedRadius.card)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            // Interactive effects
            .scaleEffect(isPressed ? 0.98 : 1)
            .brightness(isPressed ? -0.02 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle()) // Remove default NavigationLink styling
        .contentShape(Rectangle()) // Ensure the entire card is tappable
        .onTapGesture {
            // Manual tap handling for visual feedback
            hapticGenerator.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            // Reset after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
        }
    }
}

// Placeholder for the actual workout session view
// struct WorkoutSessionView: View { // Remove old placeholder
//     let exerciseName: String
//     var body: some View {
//         Text("Starting \(exerciseName) Session...")
//             .navigationTitle(exerciseName)
//             // This view will contain the camera feed, pose detection, etc.
//     }
// }

#Preview("Light Mode") {
    NavigationView {
        WorkoutSelectionView()
    }
    .environment(\.colorScheme, .light)
}

#Preview("Dark Mode") {
    NavigationView {
        WorkoutSelectionView()
    }
    .environment(\.colorScheme, .dark)
} 