import SwiftUI
import PTDesignSystem

// Using global DSColor and SColor aliases from PTDesignSystem
// fileprivate typealias DSColor = PTDesignSystem.Color
// fileprivate typealias SColor = SwiftUI.Color

struct WorkoutSelectionView: View {
    // TODO: Add ViewModel for workout logic

    // Example list of exercises
    struct Exercise: Identifiable {
        let id = UUID()
        let name: String // Display name
        let rawValue: String // Raw value for enum/storage
        let description: String
        let iconName: String // System icon name for example
        let color: SColor // Add a unique color for each exercise
    }

    let exercises = [
        Exercise(
            name: "Push-ups",
            rawValue: "pushup",
            description: "Upper body strength training focusing on chest, shoulders, and triceps",
            iconName: "pushup",
            color: ThemeColor.brassGold
        ),
        Exercise(
            name: "Sit-ups",
            rawValue: "situp",
            description: "Core strength exercise targeting abdominal muscles",
            iconName: "situp",
            color: ThemeColor.deepOps
        ),
        Exercise(
            name: "Pull-ups",
            rawValue: "pullup",
            description: "Upper body exercise focusing on back, shoulders, and arms",
            iconName: "pullup",
            color: ThemeColor.primary
        ),
        Exercise(
            name: "Run",
            rawValue: "run",
            description: "Cardiovascular training for endurance and stamina",
            iconName: "running",
            color: ThemeColor.success
        )
    ]
    
    // For staggered animations
    @State private var cardsVisible = [false, false, false, false]
    @State private var headerVisible = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.medium) {
                // Motivational header
                motivationalHeader
                    .opacity(headerVisible ? 1 : 0)
                    .offset(y: headerVisible ? 0 : -20)
                
                // Exercise cards
                exerciseCards
            }
            .padding(Spacing.contentPadding)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    ThemeColor.background,
                    ThemeColor.background.opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
        )
        .navigationTitle("Choose Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            animateContent()
        }
    }
    
    // MARK: - View Components
    
    private var motivationalHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Ready for a Challenge?")
                .heading1()
                .foregroundColor(ThemeColor.textPrimary)
            
            Text("Select an exercise to begin your workout session")
                .small()
                .foregroundColor(ThemeColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Spacing.medium)
    }
    
    private var exerciseCards: some View {
        VStack(spacing: Spacing.medium) {
            ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                ExerciseCard(
                    exercise: exercise,
                    destination: {
                        if exercise.name == "Run" {
                            return AnyView(RunWorkoutView())
                        } else {
                            // Convert from Exercise to ExerciseType based on rawValue
                            let exerciseType: ExerciseType
                            switch exercise.rawValue {
                            case "pushup":
                                exerciseType = .pushup
                            case "situp":
                                exerciseType = .situp
                            case "pullup":
                                exerciseType = .pullup
                            default:
                                exerciseType = .unknown
                            }
                            return AnyView(WorkoutSessionView(exerciseType: exerciseType))
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
    let exercise: WorkoutSelectionView.Exercise
    let destination: () -> AnyView
    
    @State private var isPressed = false
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: Spacing.medium) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(exercise.color.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(exercise.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .foregroundColor(exercise.color)
                }
                
                // Exercise info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .heading4()
                        .foregroundColor(ThemeColor.textPrimary)
                    
                    Text(exercise.description)
                        .small()
                        .foregroundColor(ThemeColor.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .caption()
                    .foregroundColor(ThemeColor.textTertiary)
            }
            .padding(Spacing.medium)
            .background(ThemeColor.cardBackground)
            .cornerRadius(CornerRadius.card)
            .shadow(color: ThemeColor.black.opacity(0.08), radius: 8, x: 0, y: 2)
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