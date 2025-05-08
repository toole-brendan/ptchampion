import SwiftUI
import PTDesignSystem // Assuming AppTheme is part of this

struct ExerciseHUDView: View {
    @Binding var repCount: Int
    @Binding var liveFeedback: String
    let elapsedTimeFormatted: String // Changed from elapsedTime: Int to take formatted string
    @Binding var isPaused: Bool
    @Binding var isSoundEnabled: Bool

    var togglePauseAction: () -> Void
    var toggleSoundAction: () -> Void

    var body: some View {
        VStack {
            // Top: Rep Counter & Live Feedback
            HStack {
                VStack(alignment: .leading) {
                    Text("REPS")
                        .font(AppTheme.GeneratedTypography.caption(size: nil))
                        .foregroundColor(Color.gray) // TODO: Replace with correct design system color AppTheme.GeneratedColors.textSecondaryOnDark
                    Text("\(repCount)")
                        .font(AppTheme.GeneratedTypography.heading(size: AppTheme.GeneratedTypography.heading1))
                        .foregroundColor(Color.white) // TODO: Replace with correct design system color AppTheme.GeneratedColors.textPrimaryOnDark
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("TIME")
                        .font(AppTheme.GeneratedTypography.caption(size: nil))
                        .foregroundColor(Color.gray) // TODO: Replace with correct design system color AppTheme.GeneratedColors.textSecondaryOnDark
                    Text(elapsedTimeFormatted)
                        .font(AppTheme.GeneratedTypography.heading(size: AppTheme.GeneratedTypography.heading1))
                        .foregroundColor(Color.white) // TODO: Replace with correct design system color AppTheme.GeneratedColors.textPrimaryOnDark
                }
            }
            .padding()
            .background(Color.black.opacity(0.7)) // TODO: Replace with correct design system color AppTheme.GeneratedColors.backgroundOverlay.opacity(0.7)
            .cornerRadius(AppTheme.GeneratedRadius.medium)
            .padding()

            Spacer() // Pushes feedback and controls down

            Text(liveFeedback)
                .font(AppTheme.GeneratedTypography.bodyBold(size: nil))
                .foregroundColor(Color.white) // TODO: Replace with correct design system color AppTheme.GeneratedColors.textPrimaryOnDark
                .padding()
                .background(Color.black.opacity(0.7)) // TODO: Replace with correct design system color AppTheme.GeneratedColors.backgroundOverlay.opacity(0.7)
                .cornerRadius(AppTheme.GeneratedRadius.small)
                .padding(.horizontal)
            
            // Bottom: Pause/Sound Controls
            HStack(spacing: 30) {
                Button { togglePauseAction() } label: {
                    Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(Color.white) // TODO: Replace with correct design system color AppTheme.GeneratedColors.textPrimaryOnDark
                }

                Button { toggleSoundAction() } label: {
                    Image(systemName: isSoundEnabled ? "speaker.wave.2.circle.fill" : "speaker.slash.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(Color.white) // TODO: Replace with correct design system color AppTheme.GeneratedColors.textPrimaryOnDark
                }
            }
            .padding()
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
        @State var elapsedTime = 125 // Example seconds
        @State var isPaused = false
        @State var isSoundEnabled = true

        // Function to format time for preview
        func formatTime(_ totalSeconds: Int) -> String {
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }

        // Add explicit return for the view
        return ExerciseHUDView(
            repCount: $repCount,
            liveFeedback: $liveFeedback,
            elapsedTimeFormatted: formatTime(elapsedTime), // Pass formatted time
            isPaused: $isPaused,
            isSoundEnabled: $isSoundEnabled,
            togglePauseAction: { isPaused.toggle() },
            toggleSoundAction: { isSoundEnabled.toggle() }
        )
        .background(Color.blue.opacity(0.3)) // Add a background to see the HUD clearly
        .previewLayout(.sizeThatFits)
    }
}
#endif 