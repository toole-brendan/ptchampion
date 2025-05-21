import SwiftUI
import Combine
import PTDesignSystem
import SwiftData
import Vision
import AudioToolbox
import UIKit

struct WorkoutSessionView: View {
    // MARK: - Properties
    let exerciseType: ExerciseType
    
    @StateObject private var viewModel: WorkoutSessionViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Add countdown state
    @State private var countdown: Int? = nil
    @State private var countdownTimer: Timer.TimerPublisher = Timer.publish(every: 1, on: .main, in: .common)
    @State private var countdownCancellable: Cancellable? = nil
    
    // MARK: - Initialization
    init(exerciseType: ExerciseType) {
        self.exerciseType = exerciseType
        
        // Create the view model with the exercise type
        _viewModel = StateObject(wrappedValue: WorkoutSessionViewModel(
            exerciseType: exerciseType
        ))
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Camera Preview (full screen background)
            CameraPreviewView(session: viewModel.cameraService.session, cameraService: viewModel.cameraService)
                .edgesIgnoringSafeArea(.all)
            
            // Pose Detection Overlay
            if let body = viewModel.detectedBody {
                PoseOverlayView(detectedBody: body, badJointNames: viewModel.problemJoints)
                    .edgesIgnoringSafeArea(.all)
            }
            
            // UI Overlay (Rep Counter, Feedback, Controls)
            ExerciseHUDView(
                repCount: $viewModel.repCount,
                liveFeedback: $viewModel.feedbackMessage,
                elapsedTimeFormatted: viewModel.elapsedTimeFormatted,
                isPaused: $viewModel.isPaused,
                isSoundEnabled: $viewModel.isSoundEnabled,
                showControls: viewModel.workoutState != .ready,
                showFullBodyWarning: $viewModel.showFullBodyWarning,
                togglePauseAction: { viewModel.togglePause() },
                toggleSoundAction: { viewModel.toggleSound() }
            )
            
            // Start Button Overlay (shown only when in ready state)
            if viewModel.workoutState == .ready && countdown == nil {
                startButtonOverlay()
                    .zIndex(1)
            }
            
            // Countdown Overlay (shown during countdown)
            if let currentCount = countdown {
                countdownOverlay(count: currentCount)
                    .zIndex(2)
            }
            
            // Camera Permission Request View
            if viewModel.workoutState == .requestingPermission {
                CameraPermissionRequestView(
                    onRequestPermission: {
                        viewModel.requestCameraPermission()
                    },
                    onCancel: {
                        dismiss()
                    }
                )
                .zIndex(2)
            }
            
            // Permission Denied View
            if viewModel.workoutState == .permissionDenied {
                permissionDeniedOverlay()
                    .zIndex(2)
            }
        }
        .onAppear {
            setupView()
            print("WorkoutSessionView appeared for \(exerciseType.displayName)")
            
            // Register for rotation events
            NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil, queue: .main
            ) { _ in
                // Small delay to ensure UI has rotated
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.cameraService.updateOutputOrientation()
                }
            }
        }
        .onDisappear {
            // Stop the countdown timer first
            stopCountdownTimer()
            
            // If the workout is still active (not finished), pause it when navigating away
            if viewModel.workoutState != .finished {
                // Pause the workout timer if it's running
                if !viewModel.isPaused {
                    viewModel.togglePause()
                }
                
                print("WorkoutSessionView disappeared while workout was active - pausing workout")
            }
            
            // Remove rotation observer
            NotificationCenter.default.removeObserver(
                self, name: UIDevice.orientationDidChangeNotification, object: nil
            )
            
            // Ensure comprehensive cleanup happens on the main actor
            // This ensures all resources are properly released even if the view disappears unexpectedly
            Task { @MainActor in
                viewModel.cleanup()
                print("WorkoutSessionView disappeared - resources cleaned up")
            }
        }
        .navigationTitle(exerciseType.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("End") {
                    if viewModel.workoutState == .counting || viewModel.workoutState == .paused {
                        viewModel.finishWorkout()
                        print("Workout ended by user - cleanup initiated")
                    } else {
                        // If workout hasn't started yet, just dismiss
                        dismiss()
                        print("View dismissed before workout started")
                    }
                }
                .foregroundColor(AppTheme.GeneratedColors.error)
                // Disable the End button if the workout is already finished to prevent multiple calls
                .disabled(viewModel.workoutState == .finished)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.switchCamera() }) {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.system(size: 20))
                }
                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
            }
        }
        .fullScreenCover(isPresented: $viewModel.showWorkoutCompleteView) {
            if let result = viewModel.completedWorkoutResult {
                WorkoutCompleteView(
                    result: result,
                    exerciseGrader: AnyExerciseGraderBox(WorkoutSessionViewModel.createGrader(for: exerciseType))
                )
                .onDisappear {
                    dismiss()
                }
            }
        }
        .alert("Save Error", isPresented: $viewModel.showAlertForSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.saveErrorMessage)
        }
        .onChange(of: modelContext) { _, newContext in
            // Update the view model's context when it changes
            viewModel.modelContext = newContext
        }
        // Listen for countdown timer
        .onReceive(countdownTimer) { _ in
            handleCountdownTick()
        }
    }
    
    // MARK: - Setup
    private func setupView() {
        // Set the model context
        viewModel.modelContext = modelContext
        
        // Check camera permission - but don't auto-start workout
        viewModel.checkCameraPermission()
    }
    
    // MARK: - Start Button Overlay
    @ViewBuilder
    private func startButtonOverlay() -> some View {
        VStack {
            Spacer()
            
            Button {
                startCountdown()
            } label: {
                Text("Ready for \(exerciseType.displayName)")
                    .font(AppTheme.GeneratedTypography.bodyBold(size: nil))
                    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    .padding()
                    .frame(width: 300)
                    .background(.ultraThinMaterial)
                    .cornerRadius(AppTheme.GeneratedRadius.medium)
            }
            // Use a more appropriate bottom padding that works across device sizes
            .padding(.bottom, 80)
        }
        // Add margin to ensure the button stays within safe viewing area
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    // MARK: - Countdown Overlay
    @ViewBuilder
    private func countdownOverlay(count: Int) -> some View {
        VStack {
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 80, weight: .bold))
                .foregroundColor(.white)
                .padding(30)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 150, height: 150)
                )
            
            Spacer()
        }
    }
    
    // MARK: - Countdown Logic
    private func startCountdown() {
        // Set initial countdown
        countdown = 5
        
        // Start the timer
        countdownTimer = Timer.publish(every: 1, on: .main, in: .common)
        countdownCancellable = countdownTimer.connect()
        
        // Play sound feedback
        if viewModel.isSoundEnabled {
            AudioServicesPlaySystemSound(1103) // System beep
        }
    }
    
    private func handleCountdownTick() {
        guard var count = countdown else { return }
        
        count -= 1
        
        // Play tick sound
        if viewModel.isSoundEnabled && count > 0 {
            AudioServicesPlaySystemSound(1103) // System beep
        }
        
        if count > 0 {
            countdown = count
        } else {
            // Countdown complete, start workout
            countdown = nil
            stopCountdownTimer()
            
            // Play start sound
            if viewModel.isSoundEnabled {
                AudioServicesPlaySystemSound(1104) // Stronger beep
                let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
                impactGenerator.prepare()
                impactGenerator.impactOccurred()
            }
            
            // Start the actual workout
            viewModel.startWorkout()
        }
    }
    
    private func stopCountdownTimer() {
        countdownCancellable?.cancel()
        countdownCancellable = nil
    }
    
    // MARK: - UI Components
    @ViewBuilder
    private func permissionDeniedOverlay() -> some View {
        VStack(spacing: AppTheme.GeneratedSpacing.medium) {
            Image(systemName: "camera.slash.fill")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
            
            PTLabel("Camera Access Denied", style: .heading)
            
            PTLabel("This feature requires camera access to track exercises. Please enable camera access in Settings.", style: .body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            let primaryButtonStyle: PTButton.ExtendedStyle = .primary
            PTButton("Open Settings", style: primaryButtonStyle) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
        .padding(AppTheme.GeneratedSpacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color(uiColor: UIColor.black.withAlphaComponent(0.85))
                .edgesIgnoringSafeArea(.all)
        )
    }
}

// MARK: - Preview
struct WorkoutSessionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WorkoutSessionView(exerciseType: .pushup)
        }
    }
}

// Preview helper if needed
#if DEBUG
extension ExerciseType {
    static var preview: ExerciseType { .pushup }
}
#endif 