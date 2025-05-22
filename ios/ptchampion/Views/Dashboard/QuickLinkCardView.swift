import SwiftUI
import PTDesignSystem

struct QuickLinkCardView: View {
    let title: String
    let icon: String
    let destination: String
    let isSystemIcon: Bool
    @State private var isActive = false
    
    var body: some View {
        Button(action: {
            isActive = true
        }) {
            VStack(alignment: .center, spacing: 16) {
                // Icon centered in circle container
                ZStack {
                    Circle()
                        .fill(AppTheme.GeneratedColors.oliveMist.opacity(0.3))
                        .frame(width: 72, height: 72)
                    
                    if isSystemIcon {
                        Image(systemName: icon)
                            .font(.system(size: 28))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    } else {
                        Image(icon)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                            .frame(width: 38, height: 38)
                    }
                }
                
                // Text label - UPPERCASE with military styling
                Text(title.uppercased())
                    .militaryMonospaced(size: 16)
                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 3,
                x: 0,
                y: 1
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            NavigationLink(
                destination: destinationView,
                isActive: $isActive,
                label: { EmptyView() }
            )
            .opacity(0) // Make the navigation link invisible
        )
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