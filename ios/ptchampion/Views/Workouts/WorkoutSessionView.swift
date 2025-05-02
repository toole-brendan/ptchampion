import SwiftUI
import AVFoundation // For status constants
import SwiftData

struct WorkoutSessionView: View {
    let exerciseName: String
    // Use @StateObject to create and keep the ViewModel alive for the view's lifecycle
    @StateObject private var viewModel: WorkoutViewModel
    
    // Use Environment to dismiss the view when done
    @Environment(\.dismiss) var dismiss
    
    // Access ModelContext
    @Environment(\.modelContext) private var modelContext

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

            // UI Overlay on top of the camera feed
            VStack {
                // Top Bar (Exercise Name, Timer - TODO)
                HStack {
                    Text(exerciseName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                    Spacer()
                    // TODO: Add Timer view
                    Text("Time: \(viewModel.elapsedTimeFormatted)")
                         .font(.system(size: 18, weight: .bold, design: .monospaced))
                         .foregroundColor(.white)
                         .shadow(radius: 2)
                }
                .padding()
                .background(Color.black.opacity(0.3))

                Spacer() // Pushes content to top and bottom

                 // Center Feedback Area
                 Text(viewModel.feedbackMessage)
                     .font(.headline)
                     .foregroundColor(.white)
                     .padding()
                     .background(Color.black.opacity(0.5))
                     .cornerRadius(10)
                     .shadow(radius: 3)
                     .padding(.bottom)

                // Bottom Bar (Rep Count, Controls)
                HStack {
                     VStack {
                         Text("REPS")
                            .font(.caption)
                            .foregroundColor(.white)
                         Text("\(viewModel.repCount)")
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                     }
                     .shadow(radius: 2)

                     Spacer()

                     // Control Buttons based on state
                     workoutControls()
                }
                 .padding()
                 .background(Color.black.opacity(0.3))

            }
            .edgesIgnoringSafeArea(.bottom) // Allow bottom bar to touch edge

            // Pose Overlay Layer if pose is detected
            if viewModel.detectedBody != nil {
                PoseOverlayView(detectedBody: viewModel.detectedBody)
                    .ignoresSafeArea()
            }

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
                .foregroundColor(Color("BrassGold"))
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
    }

    // Helper view for workout controls
    @ViewBuilder
    private func workoutControls() -> some View {
        switch viewModel.workoutState {
        case .ready:
            Button {
                viewModel.startWorkout()
            } label: {
                Label("Start", systemImage: "play.circle.fill")
                    .font(.title)
            }
            .foregroundColor(.green)
        case .counting:
            Button {
                viewModel.pauseWorkout()
            } label: {
                Label("Pause", systemImage: "pause.circle.fill")
                    .font(.title)
            }
             .foregroundColor(.yellow)
        case .paused:
            HStack(spacing: 20) {
                Button {
                    viewModel.resumeWorkout()
                } label: {
                    Label("Resume", systemImage: "play.circle.fill")
                        .font(.title)
                }
                .foregroundColor(.green)
                Button {
                    viewModel.stopWorkout()
                } label: {
                    Label("Stop", systemImage: "stop.circle.fill")
                        .font(.title)
                }
                 .foregroundColor(.red)
            }
        case .finished, .error:
             Button {
                 dismiss() // Dismiss view when finished or error
             } label: {
                 Label("Done", systemImage: "checkmark.circle.fill")
                    .font(.title)
             }
             .foregroundColor(Color("BrassGold"))
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
                 .background(Color("BrassGold"))
                 .foregroundColor(.white)
                 .cornerRadius(8)
             }
             .padding()
             .frame(maxWidth: .infinity, maxHeight: .infinity)
             .background(Color("Cream").opacity(0.95))
        }
         else if case .error(let message) = viewModel.workoutState {
             VStack {
                 Text("Workout Error")
                    .font(.title2).bold().foregroundColor(.red)
                 Text(message)
                    .multilineTextAlignment(.center)
                    .padding()
                 Button("Done") {
                     dismiss()
                 }
                 .padding(.horizontal, 16)
                 .padding(.vertical, 10)
                 .background(Color("BrassGold"))
                 .foregroundColor(.white)
                 .cornerRadius(8)
             }
             .padding()
             .frame(maxWidth: .infinity, maxHeight: .infinity)
             .background(Color("Cream").opacity(0.95))
         }
    }
}

#Preview {
    // Wrap in NavigationView for the Toolbar preview
    NavigationView {
        WorkoutSessionView(exerciseName: "Push-ups")
    }
} 