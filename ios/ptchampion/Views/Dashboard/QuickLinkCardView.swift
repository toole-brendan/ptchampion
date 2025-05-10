import SwiftUI
import PTDesignSystem

struct QuickLinkCardView: View {
    let title: String
    let icon: String
    let destination: String
    let isSystemIcon: Bool
    
    var body: some View {
        NavigationLink(destination: destinationView) {
            PTCard {
                VStack(alignment: .center, spacing: AppTheme.GeneratedSpacing.extraSmall) {
                    if isSystemIcon {
                        Image(systemName: icon)
                            .font(.system(size: 48))
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                            .frame(width: 64, height: 64)
                            .scaledToFit()
                    } else {
                        Image(icon)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                            .frame(width: 64, height: 64)
                    }
                    
                    Text(title)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                }
                .padding(AppTheme.GeneratedSpacing.itemSpacing)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 120)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Determine the destination view based on the destination string
    @ViewBuilder
    private var destinationView: some View {
        switch destination {
        case "workout-pushups":
            WorkoutSessionView(exerciseName: "Push-Ups")
        case "workout-situps":
            WorkoutSessionView(exerciseName: "Sit-Ups")
        case "workout-pullups":
            WorkoutSessionView(exerciseName: "Pull-Ups")
        case "workout-running":
            RunWorkoutView()
        default:
            Text("Unknown Destination: \(destination)")
                .padding()
        }
    }
}

#Preview {
    QuickLinkCardView(
        title: "Push-Ups",
        icon: "pushup",
        destination: "workout-pushups",
        isSystemIcon: false
    )
} 