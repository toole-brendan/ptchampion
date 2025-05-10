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
            CameraPreviewView(session: viewModel.cameraService.session)
                .edgesIgnoringSafeArea(.all)
            
            // Pose Detection Overlay
            if let body = viewModel.detectedBody {
                PoseOverlayView(detectedBody: body)
                    .edgesIgnoringSafeArea(.all)
            }
            
            // UI Overlay (Rep Counter, Feedback, Controls)
            ExerciseHUDView(
                repCount: $viewModel.repCount,
                liveFeedback: $viewModel.feedbackMessage,
                elapsedTimeFormatted: viewModel.elapsedTimeFormatted,
                isPaused: $viewModel.isPaused,
                isSoundEnabled: $viewModel.isSoundEnabled,
                togglePauseAction: { viewModel.togglePause() },
                toggleSoundAction: { viewModel.toggleSound() }
            )
            
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
                .zIndex(2) // Ensure it's on top
            }
            
            // Permission Denied View
            if viewModel.workoutState == .permissionDenied {
                permissionDeniedOverlay()
                    .zIndex(1)
            }
        }
        .onAppear {
            setupView()
        }
        .onDisappear {
            // The view model's deinit will handle cleanup
        }
        .navigationTitle(exerciseType.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("End") {
                    viewModel.finishWorkout()
                }
                .foregroundColor(AppTheme.GeneratedColors.error) // Use design system color instead of .red
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
    }
    
    // MARK: - Setup
    private func setupView() {
        // Set the model context
        viewModel.modelContext = modelContext
        
        // Start the workout
        viewModel.startWorkout()
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