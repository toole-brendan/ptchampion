import SwiftUI
import AVFoundation // For status constants
import SwiftData
import PTDesignSystem // For AppTheme

struct WorkoutSessionView: View {
    let exerciseName: String
    // Use @StateObject to create and keep the ViewModel alive for the view's lifecycle
    @StateObject private var viewModel: WorkoutViewModel
    
    // Use Environment to dismiss the view when done
    @Environment(\.dismiss) var dismiss
    
    // Access ModelContext
    @Environment(\.modelContext) private var modelContext
    
    // State for countdown animation
    @State private var countdownValue: Int = 3
    @State private var isCountingDown: Bool = false
    @State private var repAnimationScale: CGFloat = 1.0

    init(exerciseName: String) {
        self.exerciseName = exerciseName
        
        // Initialize StateObject here
        self._viewModel = StateObject(wrappedValue: WorkoutViewModel(
            exerciseName: exerciseName,
            poseDetectorService: PoseDetectorService(),
            modelContext: nil
        ))
    }

    var body: some View {
        ZStack {
            // Camera Preview Layer (using UIViewRepresentable)
            if let cameraService = viewModel.cameraService {
                CameraPreviewView(session: cameraService.session)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea() // Fallback if camera not available
            }

            // Pose Overlay Layer if pose is detected
            if viewModel.detectedBody != nil {
                PoseOverlayView(detectedBody: viewModel.detectedBody, badJointNames: viewModel.badJointNames)
                    .ignoresSafeArea()
                    .id(viewModel.poseFrameIndex) // Only redraw when new pose arrives
                    .allowsHitTesting(false)
            }
            
            // Countdown overlay if needed
            if isCountingDown {
                countdownOverlay()
            }
            
            // "Get Ready" instruction overlay
            if viewModel.workoutState == .ready && !isCountingDown {
                getReadyOverlay()
            }

            // UI Overlay on top of the camera feed
            VStack {
                // Top Bar (Exercise Name, Timer)
                HStack {
                    Text(exerciseName)
                        .font(AppTheme.GeneratedTypography.heading(size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        .shadow(radius: 2)
                    Spacer()
                    Text("Time: \(viewModel.elapsedTimeFormatted)")
                         .font(.system(size: 18, weight: .bold, design: .monospaced))
                         .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                         .shadow(radius: 2)
                         .accessibilityLabel("Elapsed time: \(viewModel.elapsedTimeFormatted)")
                }
                .padding(AppTheme.GeneratedSpacing.medium)
                .background(AppTheme.GeneratedColors.background.opacity(0.3))

                Spacer() // Pushes content to top and bottom

                // Center Feedback Area with color-coded feedback
                feedbackView()
                    .transition(.opacity)
                    .animation(.easeInOut, value: viewModel.feedbackMessage)

                Spacer()

                // Bottom Bar (Rep Count, Controls)
                HStack {
                     // Rep counter
                     repCounterView()
                     
                     Spacer()

                     // Control Buttons based on state
                     workoutControls()
                }
                 .padding(AppTheme.GeneratedSpacing.medium)
                 .background(AppTheme.GeneratedColors.background.opacity(0.3))

            }
            .edgesIgnoringSafeArea(.bottom) // Allow bottom bar to touch edge

            // Display error messages or permission prompts
            permissionOrErrorOverlay()
        }
        .navigationTitle(exerciseName) // Set title again for back button etc.
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true) // Hide default back button
        .toolbar { // Custom toolbar for cancel button
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    viewModel.stopWorkout() // Use stop to ensure cleanup
                    dismiss()
                }
                .foregroundColor(AppTheme.GeneratedColors.accent)
            }
        }
        .onAppear {
            // Inject model context when view appears
            if viewModel.modelContext == nil {
                viewModel.modelContext = modelContext
            }
            
            // Initialize camera only when view appears to avoid multiple initializations
            viewModel.initializeCamera()
            viewModel.startCamera()
        }
        .onDisappear {
            print("WorkoutSessionView disappeared - stopping workout")
            viewModel.stopWorkout() // Ensure cleanup when view disappears
            viewModel.stopCamera()
            viewModel.releaseCamera() // Release camera resources
        }
        .background(Color.black) // Background for the whole view
        .onReceive(viewModel.repCompletedPublisher) { _ in
            // Animate rep counter when a rep is completed
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                repAnimationScale = 1.3
            }
            
            // Reset scale after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    repAnimationScale = 1.0
                }
            }
        }
    }
    
    // Rep counter view with animation
    @ViewBuilder
    private func repCounterView() -> some View {
        VStack {
            Text("REPS")
               .font(.caption)
               .foregroundColor(AppTheme.GeneratedColors.textPrimary)
               .accessibilityHidden(true)
            Text("\(viewModel.repCount)")
               .font(.system(size: 36, weight: .bold, design: .monospaced))
               .foregroundColor(AppTheme.GeneratedColors.textPrimary)
               .scaleEffect(repAnimationScale)
               .animation(.spring(), value: viewModel.repCount)
               .accessibilityLabel("Reps completed: \(viewModel.repCount)")
        }
        .shadow(radius: 2)
    }
    
    // Feedback message view with color coding
    @ViewBuilder
    private func feedbackView() -> some View {
        Text(viewModel.feedbackMessage)
            .font(.headline)
            .foregroundColor(AppTheme.GeneratedColors.textPrimary)
            .padding()
            .background(feedbackBackgroundColor().opacity(0.5))
            .cornerRadius(10)
            .shadow(radius: 3)
            .padding(.bottom)
            .accessibilityLabel("Feedback: \(viewModel.feedbackMessage)")
    }
    
    // Determine background color based on feedback message
    private func feedbackBackgroundColor() -> Color {
        if viewModel.feedbackMessage.contains("✅") {
            return AppTheme.GeneratedColors.success
        } else if viewModel.feedbackMessage.contains("⚠️") {
            return AppTheme.GeneratedColors.warning
        } else {
            return AppTheme.GeneratedColors.background
        }
    }
    
    // Countdown overlay shown during the 3-2-1 countdown
    @ViewBuilder
    private func countdownOverlay() -> some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack {
                Text("\(countdownValue)")
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    .padding()
                    .transition(.scale)
                    .id("countdown-\(countdownValue)") // Force redraw on value change
                
                Text("Get ready...")
                    .font(.title)
                    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
            }
        }
        .transition(.opacity)
    }
    
    // "Get Ready" instruction overlay
    @ViewBuilder
    private func getReadyOverlay() -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: AppTheme.GeneratedSpacing.large) {
                Text("Position yourself so your whole body fits in the frame")
                    .font(.title2)
                    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button {
                    startCountdown()
                } label: {
                    Text("Start")
                        .font(.title2)
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        .padding()
                        .background(AppTheme.GeneratedColors.success)
                        .cornerRadius(AppTheme.GeneratedRadius.button)
                }
            }
            .padding()
            .background(AppTheme.GeneratedColors.background.opacity(0.7))
            .cornerRadius(AppTheme.GeneratedRadius.card)
            .padding()
        }
    }
    
    // Start the 3-2-1 countdown animation
    private func startCountdown() {
        isCountingDown = true
        
        // Schedule countdown animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(.easeInOut) {
                countdownValue = 2
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(.easeInOut) {
                    countdownValue = 1
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation(.easeInOut) {
                        isCountingDown = false
                        
                        // Reset for next time
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            countdownValue = 3
                        }
                        
                        // Start the workout after countdown finishes
                        viewModel.startWorkout()
                    }
                }
            }
        }
    }

    // Helper view for workout controls
    @ViewBuilder
    private func workoutControls() -> some View {
        switch viewModel.workoutState {
        case .ready:
            Button {
                startCountdown()
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppTheme.GeneratedColors.success)
                    .shadow(radius: 2)
                    .accessibilityLabel("Start workout")
            }
        case .counting:
            Button {
                viewModel.pauseWorkout()
            } label: {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppTheme.GeneratedColors.warning)
                    .shadow(radius: 2)
                    .accessibilityLabel("Pause workout")
            }
        case .paused:
            HStack(spacing: 20) {
                Button {
                    viewModel.resumeWorkout()
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(AppTheme.GeneratedColors.success)
                        .shadow(radius: 2)
                        .accessibilityLabel("Resume workout")
                }
                Button {
                    viewModel.stopWorkout()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(AppTheme.GeneratedColors.error)
                        .shadow(radius: 2)
                        .accessibilityLabel("Stop workout")
                }
            }
        case .finished, .error:
             Button {
                 dismiss() // Dismiss view when finished or error
             } label: {
                 Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppTheme.GeneratedColors.accent)
                    .shadow(radius: 2)
                    .accessibilityLabel("Done")
             }
        default:
            EmptyView() // Handle initializing, requestingPermission states
        }
    }

    // Helper view for permission/error overlays
    @ViewBuilder
    private func permissionOrErrorOverlay() -> some View {
        if viewModel.workoutState == .permissionDenied {
             VStack {
                 Text("Camera Access Required")
                    .font(.title2).bold()
                 Text(viewModel.errorMessage ?? "Please enable camera access in Settings.")
                    .multilineTextAlignment(.center)
                    .padding()
                 Button("Open Settings") {
                    // Deep link to app settings
                    if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                 }
                 .padding(.horizontal, 16)
                 .padding(.vertical, 10)
                 .background(AppTheme.GeneratedColors.accent)
                 .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                 .cornerRadius(8)
             }
             .padding()
             .frame(maxWidth: .infinity, maxHeight: .infinity)
             .background(AppTheme.GeneratedColors.background.opacity(0.95))
        }
         else if case .error(let message) = viewModel.workoutState {
             VStack {
                 Text("Workout Error")
                    .font(.title2).bold().foregroundColor(AppTheme.GeneratedColors.error)
                 Text(message)
                    .multilineTextAlignment(.center)
                    .padding()
                 Button("Done") {
                     dismiss()
                 }
                 .padding(.horizontal, 16)
                 .padding(.vertical, 10)
                 .background(AppTheme.GeneratedColors.accent)
                 .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                 .cornerRadius(8)
             }
             .padding()
             .frame(maxWidth: .infinity, maxHeight: .infinity)
             .background(AppTheme.GeneratedColors.background.opacity(0.95))
         }
    }
}

#Preview {
    // Wrap in NavigationView for the Toolbar preview
    NavigationView {
        WorkoutSessionView(exerciseName: "Push-ups")
    }
} 