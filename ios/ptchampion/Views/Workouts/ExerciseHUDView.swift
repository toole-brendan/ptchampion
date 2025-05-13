import SwiftUI
import PTDesignSystem

struct ExerciseHUDView: View {
    @Binding var repCount: Int
    @Binding var liveFeedback: String
    let elapsedTimeFormatted: String
    @Binding var isPaused: Bool
    @Binding var isSoundEnabled: Bool
    let showControls: Bool // New parameter to control visibility of bottom controls

    var togglePauseAction: () -> Void
    var toggleSoundAction: () -> Void

    var body: some View {
        VStack {
            // Top: Rep Counter & Live Feedback
            HStack {
                VStack(alignment: .leading) {
                    Text("REPS")
                        .caption()
                        .foregroundColor(Color.textSecondary)
                    Text("\(repCount)")
                        .heading1()
                        .foregroundColor(Color.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("TIME")
                        .caption()
                        .foregroundColor(Color.textSecondary)
                    Text(elapsedTimeFormatted)
                        .heading1()
                        .foregroundColor(Color.textPrimary)
                }
            }
            .padding()
            .background(.thinMaterial) // Using system blur material for better transparency
            .cornerRadius(CornerRadius.medium)
            .padding()

            Spacer() // Pushes feedback and controls down

            // Only show feedback if controls are shown (not in ready state)
            if showControls {
                Text(liveFeedback)
                    .bodyBold()
                    .foregroundColor(Color.textPrimary)
                    .padding()
                    .background(.thinMaterial) // Using system blur material for better transparency
                    .cornerRadius(CornerRadius.small)
                    .padding(.horizontal)
            }
            
            // Bottom: Pause/Sound Controls - only shown when workout is active
            if showControls {
                HStack(spacing: 30) {
                    Button { togglePauseAction() } label: {
                        Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(Color.textPrimary)
                    }

                    Button { toggleSoundAction() } label: {
                        Image(systemName: isSoundEnabled ? "speaker.wave.2.circle.fill" : "speaker.slash.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(Color.textPrimary)
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
        @State var isPaused = false
        @State var isSoundEnabled = true

        // Add explicit return for the view
        return ExerciseHUDView(
            repCount: $repCount,
            liveFeedback: $liveFeedback,
            elapsedTimeFormatted: "01:35",
            isPaused: $isPaused,
            isSoundEnabled: $isSoundEnabled,
            showControls: true, // Show controls in this preview
            togglePauseAction: { },
            toggleSoundAction: { }
        )
        .background(Color.black.opacity(0.5) // Lighter background for preview
        .previewLayout(.sizeThatFits)
    }
}
#endif 