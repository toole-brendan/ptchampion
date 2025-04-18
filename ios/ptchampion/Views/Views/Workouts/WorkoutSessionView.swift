import SwiftUI
import AVFoundation // For status constants
import SwiftData

struct WorkoutSessionView: View {
    let exerciseName: String
    // Use @StateObject to create and keep the ViewModel alive for the view's lifecycle
    @StateObject private var viewModel: WorkoutViewModel

    // Access CameraService instance through ViewModel (if needed directly, e.g., for preview layer)
    // This assumes CameraService is reference type and accessible. May need refactoring.
    private let cameraService: CameraService // Assuming default init for now

    // Access ModelContext
    @Environment(\.modelContext) private var modelContext

    // Use Environment to dismiss the view when done
    @Environment(\.dismiss) var dismiss

    init(exerciseName: String) {
        self.exerciseName = exerciseName
        let camService = CameraService() // Create instance
        self.cameraService = camService
        // Initialize StateObject here, passing the service instances
        self._viewModel = StateObject(wrappedValue: WorkoutViewModel(exerciseName: exerciseName,
                                                                  cameraService: camService,
                                                                  poseDetectorService: PoseDetectorService(),
                                                                  modelContext: nil))
    }

    var body: some View {
        ZStack {
            // Camera Preview Layer (using UIViewRepresentable)
            // Pass the AVCaptureSession from the CameraService instance
            CameraPreviewView(session: cameraService.session)
                .ignoresSafeArea()
                .onAppear(perform: viewModel.startCamera) // Start camera when view appears
                .onDisappear(perform: viewModel.stopCamera) // Stop camera when view disappears

            // UI Overlay on top of the camera feed
            VStack {
                // Top Bar (Exercise Name, Timer - TODO)
                HStack {
                    Text(exerciseName)
                        .headingStyle(size: 20, color: .white)
                        .shadow(radius: 2)
                    Spacer()
                    // TODO: Add Timer view
                    Text("Time: \(viewModel.elapsedTimeFormatted)")
                         .statsNumberStyle(size: 18, color: .white)
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
                            .labelStyle(color: .white)
                         Text("\(viewModel.repCount)")
                            .statsNumberStyle(size: 36, color: .white)
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

            // Pose Overlay Layer
            PoseOverlayView(detectedBody: viewModel.detectedBody)
                .ignoresSafeArea()

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
                .foregroundColor(.brassGold)
            }
        }
        .onAppear {
             // Inject model context when view appears
             // This ensures the context from the environment is correctly passed.
             if viewModel.modelContext == nil {
                 viewModel.modelContext = modelContext
             }
            viewModel.startCamera() // Start camera when view appears
        }
        .onDisappear {
            viewModel.stopWorkout() // Ensure cleanup when view disappears
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
             .foregroundColor(.brassGold)
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
                 .buttonStyle(PrimaryButtonStyle())
             }
             .padding()
             .frame(maxWidth: .infinity, maxHeight: .infinity)
             .background(Color.tacticalCream.opacity(0.95))
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
                 .buttonStyle(PrimaryButtonStyle())
             }
             .padding()
             .frame(maxWidth: .infinity, maxHeight: .infinity)
             .background(Color.tacticalCream.opacity(0.95))
         }
    }
}

#Preview {
    // Wrap in NavigationView for the Toolbar preview
    NavigationView {
        WorkoutSessionView(exerciseName: "Push-ups")
    }
} 