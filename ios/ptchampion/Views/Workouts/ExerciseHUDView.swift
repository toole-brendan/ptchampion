// ios/ptchampion/Views/Workouts/ExerciseHUDView.swift

import SwiftUI
import PTDesignSystem

struct ExerciseHUDView: View {
    @Binding var repCount: Int
    @Binding var liveFeedback: String
    let elapsedTimeFormatted: String
    @Binding var isSoundEnabled: Bool
    let showControls: Bool // New parameter to control visibility of bottom controls
    @Binding var showFullBodyWarning: Bool // New parameter to show full body warning

    var toggleSoundAction: () -> Void

    var body: some View {
        VStack {
            // Top: Rep Counter & Live Feedback
            HStack {
                VStack(alignment: .leading) {
                    Text("REPS")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    Text("\(repCount)")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("TIME")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    Text(elapsedTimeFormatted)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                }
            }
            .padding()
            .padding()

            Spacer() // Pushes feedback and controls down

            // Show full body warning if needed
            if showControls && showFullBodyWarning {
                Text(liveFeedback)
                    .font(AppTheme.GeneratedTypography.bodyBold(size: nil))
                    .foregroundColor(AppTheme.GeneratedColors.error)
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(AppTheme.GeneratedRadius.small)
                    .padding(.horizontal)
            }
            // Only show regular feedback if controls are shown and no warning is active
            // and only if it's not a status message like "Workout active" or "Workout paused"
            else if showControls && !liveFeedback.contains("Workout") {
                Text(liveFeedback)
                    .font(AppTheme.GeneratedTypography.bodyBold(size: nil))
                    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    .padding()
                    .background(.thinMaterial) // Using system blur material for better transparency
                    .cornerRadius(AppTheme.GeneratedRadius.small)
                    .padding(.horizontal)
            }
            
            // Bottom: Pause/Sound Controls - only shown when workout is active
            if showControls {
                HStack(spacing: 30) {
                    // Pause/play button removed, leaving only sound toggle
                    Button { toggleSoundAction() } label: {
                        Image(systemName: isSoundEnabled ? "speaker.wave.2.circle.fill" : "speaker.slash.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    }
                }
                .padding()
            }
        }
        .padding() // Overall padding for the overlay content
    }
}

// Preview for ExerciseHUDView
#if DEBUG
struct ExerciseHUDView_Previews: PreviewProvider {
    static var previews: some View {
        // Create some mock state for the preview
        @State var repCount = 10
        @State var liveFeedback = "Keep it up!"
        @State var isSoundEnabled = true
        @State var showFullBodyWarning = false

        // Add explicit return for the view
        return ExerciseHUDView(
            repCount: $repCount,
            liveFeedback: $liveFeedback,
            elapsedTimeFormatted: "01:35",
            isSoundEnabled: $isSoundEnabled,
            showControls: true, // Show controls in this preview
            showFullBodyWarning: $showFullBodyWarning,
            toggleSoundAction: { }
        )
        .background(Color.black.opacity(0.5)) // Lighter background for preview
        .previewLayout(.sizeThatFits)
    }
}
#endif 