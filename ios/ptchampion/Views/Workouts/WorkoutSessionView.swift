// ios/ptchampion/Views/Workouts/WorkoutSessionView.swift

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
    @EnvironmentObject var tabBarVisibility: TabBarVisibilityManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Add countdown state
    @State private var countdown: Int? = nil
    @State private var countdownTimer: Timer.TimerPublisher = Timer.publish(every: 1, on: .main, in: .common)
    @State private var countdownCancellable: Cancellable? = nil
    
    // MARK: - Initialization
    init(exerciseType: ExerciseType) {
        print("DEBUG: [WorkoutSessionView] Initializing view for \(exerciseType.rawValue)")
        self.exerciseType = exerciseType
        
        // Create the view model with the exercise type
        _viewModel = StateObject(wrappedValue: WorkoutSessionViewModel(
            exerciseType: exerciseType
        ))
        print("DEBUG: [WorkoutSessionView] ViewModel created with @StateObject wrapper")
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
            if viewModel.workoutState == .counting {
                ExerciseHUDView(
                    repCount: $viewModel.repCount,
                    liveFeedback: $viewModel.feedbackMessage,
                    elapsedTimeFormatted: viewModel.elapsedTimeFormatted,
                    isSoundEnabled: $viewModel.isSoundEnabled,
                    showControls: true,
                    showFullBodyWarning: $viewModel.showFullBodyWarning,
                    toggleSoundAction: { viewModel.toggleSound() }
                )
            }
            
            // Start Button Overlay (shown only when in ready state)
            if viewModel.workoutState == .ready && countdown == nil {
                startButtonOverlay()
                    .zIndex(1) // Ensure it's on top
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
                        // Print statement moved outside ViewBuilder context
                        let _ = print("DEBUG: [WorkoutSessionView] Camera permission request button tapped")
                        viewModel.requestCameraPermission()
                    },
                    onCancel: {
                        // Print statement moved outside ViewBuilder context
                        let _ = print("DEBUG: [WorkoutSessionView] Camera permission cancel button tapped")
                        dismiss()
                    }
                )
                .zIndex(2)
            }
            
            // Permission Denied/Error Overlay
            if isInErrorOrPermissionDeniedState {
                permissionOrErrorOverlay()
                    .zIndex(1)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .hideTabBar(!tabBarVisibility.isTabBarVisible)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    // Print statement moved outside ViewBuilder context
                    let _ = print("DEBUG: [WorkoutSessionView] End button tapped, workout state: \(viewModel.workoutState)")
                    handleEndWorkout()
                } label: {
                    Text("End")
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay(
                            Rectangle()
                                .stroke(Color.red, lineWidth: 2)
                        )
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.switchCamera()
                } label: {
                    Image(systemName: "camera.rotate.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 22))
                }
            }
        }
        .onAppear {
            print("DEBUG: [WorkoutSessionView] onAppear triggered for \(exerciseType.displayName)")
            
            // Hide tab bar using the visibility manager
            tabBarVisibility.hideTabBar()
            
            // Setup model context
            DispatchQueue.main.async {
                viewModel.modelContext = modelContext
            }
            
            // Register for rotation events with immediate update
            NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil, 
                queue: .main
            ) { _ in
                print("DEBUG: [WorkoutSessionView] Device orientation changed")
                
                // Use the ViewModel's orientation handler
                viewModel.handleOrientationChange()
                
                // Also update the UI after a small delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Force view refresh if needed
                    if let windowScene = UIApplication.shared.windows.first?.windowScene {
                        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
                    }
                }
            }
            
            // Initial orientation setup
            viewModel.handleOrientationChange()
        }
        .onDisappear {
            // Stop the countdown timer first
            print("DEBUG: [WorkoutSessionView] onDisappear triggered - starting cleanup sequence")
            stopCountdownTimer()
            
            // Show tab bar using the visibility manager
            tabBarVisibility.showTabBar()
            
            // Remove rotation observer
            NotificationCenter.default.removeObserver(
                self, name: UIDevice.orientationDidChangeNotification, object: nil
            )
            print("DEBUG: [WorkoutSessionView] Removed rotation observer")
            
            // Use async method with explicit @MainActor to avoid threading issues
            // and prevent "publishing changes from within view updates" error
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("DEBUG: [WorkoutSessionView] Executing delayed cleanup")
                
                // If the workout is still active (not finished), pause it when navigating away
                if self.viewModel.workoutState != .finished {
                    print("DEBUG: [WorkoutSessionView] Workout not finished, pausing workout")
                    
                    // Pause the workout timer if it's running
                    if !self.viewModel.isPaused {
                        print("DEBUG: [WorkoutSessionView] Pausing workout because view is disappearing")
                        self.viewModel.togglePause()
                    }
                }
                
                // Perform cleanup asynchronously to avoid SwiftUI update cycles
                Task {
                    print("DEBUG: [WorkoutSessionView] Starting Task for viewModel cleanup")
                    await MainActor.run {
                        print("DEBUG: [WorkoutSessionView] Calling cleanup() on MainActor")
                        self.viewModel.cleanup()
                        print("DEBUG: [WorkoutSessionView] ViewModel cleanup completed")
                    }
                }
            }
            
            print("DEBUG: [WorkoutSessionView] onDisappear completed")
        }
        .onChange(of: modelContext) { _, newContext in
            // Update the view model's context when it changes
            print("DEBUG: [WorkoutSessionView] ModelContext changed")
            DispatchQueue.main.async {
                print("DEBUG: [WorkoutSessionView] Updating viewModel.modelContext")
                viewModel.modelContext = newContext
            }
        }
        .fullScreenCover(isPresented: $viewModel.showWorkoutCompleteView) {
            // Print statement moved outside ViewBuilder content
            let _ = print("DEBUG: [WorkoutSessionView] Showing WorkoutCompleteView for result: \(viewModel.completedWorkoutResult?.id ?? UUID())")
            
            if let result = viewModel.completedWorkoutResult {
                WorkoutCompleteView(
                    result: result,
                    exerciseGrader: AnyExerciseGraderBox(WorkoutSessionViewModel.createGrader(for: exerciseType))
                )
                .onDisappear {
                    // Print statement moved outside ViewBuilder context (wrap in closure)
                    let _ = print("DEBUG: [WorkoutSessionView] WorkoutCompleteView disappeared, dismissing parent view")
                    DispatchQueue.main.async {
                        dismiss()
                    }
                }
            }
        }
        .alert("Save Error", isPresented: $viewModel.showAlertForSaveError) {
            Button("OK", role: .cancel) {
                // Print statement moved outside ViewBuilder context
                let _ = print("DEBUG: [WorkoutSessionView] Save error alert dismissed")
            }
        } message: {
            Text(viewModel.saveErrorMessage)
        }
        // Listen for countdown timer
        .onReceive(countdownTimer) { _ in
            print("DEBUG: [WorkoutSessionView] Countdown timer tick received")
            handleCountdownTick()
        }
    }
    
    // MARK: - End Workout Handler
    private func handleEndWorkout() {
        print("DEBUG: [WorkoutSessionView] handleEndWorkout() called, state: \(viewModel.workoutState)")
        
        if viewModel.workoutState == .counting || viewModel.workoutState == .paused {
            print("DEBUG: [WorkoutSessionView] Workout active, calling finishWorkout()")
            viewModel.finishWorkout()
        } else {
            print("DEBUG: [WorkoutSessionView] Workout not active, dismissing view")
            dismiss()
        }
    }
    
    // MARK: - Start Button Overlay
    @ViewBuilder
    private func startButtonOverlay() -> some View {
        // Print statement moved outside ViewBuilder context
        let _ = print("DEBUG: [WorkoutSessionView] Rendering startButtonOverlay()")
        
        return VStack {
            // Top: Exercise name and subheadline
            Text(exerciseType.displayName.uppercased())
                .font(.system(size: 48, weight: .heavy))
                .tracking(2) // Add letter spacing
                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                .multilineTextAlignment(.center)
            Text("You have two minutes to complete as many valid reps as possible.")
                .font(.subheadline)
                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
            
            Spacer()  // pushes content to top and bottom
            
            // Bottom: Instruction and GO button
            Text("Press GO and assume starting position.")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                .multilineTextAlignment(.center)
                .italic()
                .padding(.bottom, 16)
            
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(AppTheme.GeneratedColors.brassGold)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "play.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.black)
                        .padding(.leading, 3) // Adjust visual centering due to triangle shape
                }
            }
            .onTapGesture {
                print("DEBUG: [WorkoutSessionView] Start button tapped, beginning countdown")
                startCountdown()
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal)
        .padding(.top, 50) // ensure content is within safe area at top
    }
    
    // MARK: - Countdown Overlay
    @ViewBuilder
    private func countdownOverlay(count: Int) -> some View {
        // Print statement moved outside ViewBuilder context
        let _ = print("DEBUG: [WorkoutSessionView] Rendering countdownOverlay() with count: \(count)")
        
        return VStack {
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 80, weight: .bold))
                .foregroundColor(AppTheme.GeneratedColors.brassGold)
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
        print("DEBUG: [WorkoutSessionView] Starting countdown sequence")
        
        // Stop any existing countdown
        stopCountdownTimer()
        
        // Defer setting the countdown to the next render cycle
        DispatchQueue.main.async {
            // Set initial countdown
            print("DEBUG: [WorkoutSessionView] Setting countdown to 5 (async)")
            self.countdown = 5
            
            // Start the timer
            self.countdownTimer = Timer.publish(every: 1, on: .main, in: .common)
            self.countdownCancellable = self.countdownTimer.connect()
            
            // Play sound feedback
            if self.viewModel.isSoundEnabled {
                print("DEBUG: [WorkoutSessionView] Playing countdown start sound")
                AudioServicesPlaySystemSound(1103) // System beep
            }
        }
    }
    
    private func handleCountdownTick() {
        guard var count = countdown else {
            print("DEBUG: [WorkoutSessionView] Countdown tick received but countdown is nil!")
            return
        }
        
        count -= 1
        print("DEBUG: [WorkoutSessionView] Countdown tick: \(count)")
        
        // Play tick sound
        if viewModel.isSoundEnabled && count > 0 {
            AudioServicesPlaySystemSound(1103) // System beep
        }
        
        if count > 0 {
            // Update countdown value
            DispatchQueue.main.async {
                print("DEBUG: [WorkoutSessionView] Updating countdown to \(count) (async)")
                countdown = count
            }
        } else {
            // Countdown complete, prepare to start workout
            print("DEBUG: [WorkoutSessionView] Countdown complete, preparing to start workout")
            
            // Clear countdown and stop timer first
            DispatchQueue.main.async {
                print("DEBUG: [WorkoutSessionView] Clearing countdown (async)")
                countdown = nil
            }
            stopCountdownTimer()
            
            // Play start sound
            if viewModel.isSoundEnabled {
                print("DEBUG: [WorkoutSessionView] Playing workout start sound")
                AudioServicesPlaySystemSound(1104) // Stronger beep
                let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
                impactGenerator.prepare()
                impactGenerator.impactOccurred()
            }
            
            // Start the actual workout in the next render cycle
            DispatchQueue.main.async {
                print("DEBUG: [WorkoutSessionView] Starting workout (async)")
                viewModel.startWorkout()
            }
        }
    }
    
    private func stopCountdownTimer() {
        if countdownCancellable != nil {
            print("DEBUG: [WorkoutSessionView] Stopping countdown timer")
            countdownCancellable?.cancel()
            countdownCancellable = nil
        }
    }
    
    // MARK: - UI Components
    @ViewBuilder
    private func permissionOrErrorOverlay() -> some View {
        // Print statement moved outside ViewBuilder context
        let _ = print("DEBUG: [WorkoutSessionView] Rendering permissionOrErrorOverlay()")
        
        return VStack(spacing: AppTheme.GeneratedSpacing.medium) {
            // Use the isInPermissionDeniedState property for icon and text selection
            let isPermissionDenied = viewModel.workoutState == .permissionDenied
            
            Image(systemName: isPermissionDenied ? "location.slash.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(isPermissionDenied ? 
                                 AppTheme.GeneratedColors.textPrimaryOnDark : 
                                 AppTheme.GeneratedColors.warning)
            
            PTLabel(isPermissionDenied ? 
                   "Location Access Denied" : "Error", 
                   style: .heading)
            
            PTLabel(viewModel.errorMessage ?? 
                   "This feature requires location access to track runs. Please enable location access in Settings.", 
                   style: .body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            let primaryButtonStyle: PTButton.ExtendedStyle = .primary
            if isPermissionDenied {
                PTButton("Open Settings", style: primaryButtonStyle) {
                    print("DEBUG: [WorkoutSessionView] Open Settings button tapped")
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } else {
                PTButton("Dismiss", style: primaryButtonStyle) {
                    print("DEBUG: [WorkoutSessionView] Dismiss error button tapped")
                    DispatchQueue.main.async {
                        print("DEBUG: [WorkoutSessionView] Clearing error message (async)")
                        viewModel.errorMessage = nil
                        dismiss()
                    }
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
    
    // Add a computed property to check if in error state
    private var isInErrorOrPermissionDeniedState: Bool {
        if case .permissionDenied = viewModel.workoutState { return true }
        if case .error = viewModel.workoutState { return true }
        return false
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