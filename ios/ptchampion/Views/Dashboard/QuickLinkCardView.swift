import SwiftUI
import PTDesignSystem

struct QuickLinkCardView: View {
    let title: String
    let icon: String
    let destination: String
    let isSystemIcon: Bool
    
    var body: some View {
        NavigationLink(destination: destinationView) {
            VStack(alignment: .center, spacing: Spacing.extraSmall) {
                if isSystemIcon {
                    Image(systemName: icon)
                        .font(.system(size: 48))
                        .foregroundColor(ThemeColor.textPrimary)
                        .frame(width: 64, height: 64)
                        .scaledToFit()
                } else {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(ThemeColor.textPrimary)
                        .frame(width: 64, height: 64)
                }
                
                Text(title)
                    .small(weight: .semibold, design: .monospaced)
                    .foregroundColor(ThemeColor.textPrimary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
            }
            .padding(Spacing.contentPadding)
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .center)
            .card(variant: .interactive)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Determine the destination view based on the destination string
    @ViewBuilder
    private var destinationView: some View {
        switch destination {
        case "workout-pushups":
            WorkoutSessionView(exerciseType: .pushup)
        case "workout-situps":
            WorkoutSessionView(exerciseType: .situp)
        case "workout-pullups":
            WorkoutSessionView(exerciseType: .pullup)
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