// ios/ptchampion/Views/Workouts/WorkoutSessionView.swift

import SwiftUI
import Combine
import PTDesignSystem
import SwiftData
import Vision
import AudioToolbox
import UIKit
import Foundation

struct WorkoutSessionView: View {
    // MARK: - Properties
    let exerciseType: ExerciseType
    
    @StateObject private var viewModel: WorkoutSessionViewModel
    @EnvironmentObject var tabBarVisibility: TabBarVisibilityManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Legacy state objects (kept for compatibility but no longer used in new flow)
    @StateObject private var startingPositionValidator = StartingPositionValidator()
    
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
            
            // Visual guides are now integrated into AutoPositionOverlay
            
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
            
            // Simple Rep Feedback removed to prevent distraction
            
            // New Auto Position Overlay (replaces old start button and countdown)
            if [.ready, .waitingForPosition, .positionDetected, .countdown].contains(viewModel.workoutState) {
                AutoPositionOverlay(
                    workoutState: viewModel.workoutState,
                    positionHoldProgress: viewModel.positionHoldProgress,
                    countdownValue: viewModel.countdownValue,
                    onStartPressed: {
                        print("DEBUG: [WorkoutSessionView] GO button pressed - starting position detection")
                        viewModel.startPositionDetection()
                    }
                )
                .zIndex(1)
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
            
            // Apply quick calibration to view model (using simplified approach)
            viewModel.applyQuickCalibration(from: "simplified")
            
            // Register for rotation events with improved debouncing
            NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil, 
                queue: .main
            ) { [weak viewModel] _ in
                // Add delay to prevent rapid calls
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    guard let viewModel = viewModel else { return }
                    
                    print("DEBUG: [WorkoutSessionView] Device orientation changed")
                    
                    // Only call if not already processing
                    if !viewModel.isRecalibrating {
                        viewModel.handleOrientationChange()
                        // Update quick calibration for new orientation
                        viewModel.updateQuickCalibrationForOrientation("simplified")
                    }
                }
            }
            
            // Initial orientation setup
            viewModel.handleOrientationChange()
        }
        .onDisappear {
            print("DEBUG: [WorkoutSessionView] onDisappear triggered - starting cleanup sequence")
            
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
                    result: result.toWorkoutResult(),
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

        // Auto position detection is now handled by the ViewModel

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
    
    // MARK: - Legacy Methods (Replaced by AutoPositionOverlay and ViewModel)
    // All countdown and position checking logic has been moved to the ViewModel
    // and is now handled by the AutoPositionOverlay component
    
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
