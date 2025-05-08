import SwiftUI
import Combine
import PTDesignSystem
import SwiftData // Import SwiftData for ModelContext
import Vision // Needed for VNHumanBodyPoseObservation.JointName
import AudioToolbox // For system sounds
import UIKit // For haptics

// Dummy Grader for types not yet implemented
final class PlaceholderGrader: ObservableObject, ExerciseGraderProtocol {
    @Published var currentPhaseDescription: String = "Not Implemented"
    @Published var repCount: Int = 0
    @Published var formQualityAverage: Double = 0.0
    @Published var lastFormIssue: String? = nil
    @Published var problemJoints: Set<VNHumanBodyPoseObservation.JointName> = [] // Conform to protocol

    func resetState() {
        repCount = 0
        currentPhaseDescription = "Grader not implemented for this exercise."
        lastFormIssue = nil
        problemJoints = []
    }

    func gradePose(body: DetectedBody) -> GradingResult {
        return .inProgress(phase: "Grading not implemented.")
    }

    func calculateFinalScore() -> Double? {
        return nil
    }
}

struct CameraExerciseView: View {
    // Exercise type to determine which grader to use
    let exerciseType: ExerciseType // Assuming ExerciseType enum exists (e.g., .pushup, .situp)

    @StateObject private var cameraService = CameraService()
    @StateObject private var poseDetector = PoseDetectorService()
    @StateObject private var exerciseGraderBox: AnyExerciseGraderBox
    @StateObject private var workoutTimer = WorkoutTimer() // New WorkoutTimer

    @Environment(\.modelContext) private var modelContext // For saving workout data

    @State private var detectedBody: DetectedBody? = nil
    @State private var permissionDenied = false
    @State private var showPermissionRequest = true
    
    // Exercise State
    @State private var repCount: Int = 0
    @State private var liveFeedback: String = "Prepare for exercise."
    @State private var isWorkoutPaused: Bool = false // Renamed from isPaused to clarify its scope
    @State private var isSoundEnabled: Bool = true // Or load from user prefs
    @State private var currentWorkoutSessionID: UUID? // To link reps to a session

    // Timer State - REMOVED, managed by WorkoutTimer
    // @State private var elapsedTime: Int = 0 // in seconds
    // @State private var timerSubscription: Cancellable? = nil
    // @State private var workoutStartTime: Date? = nil

    @State private var cancellables = Set<AnyCancellable>()

    // Navigation state
    @Environment(\.dismiss) private var dismiss
    @State private var showWorkoutCompleteView = false
    @State private var completedWorkoutResult: WorkoutResultSwiftData?
    @State private var showAlertForSaveError = false
    @State private var saveErrorMessage = ""

    // Initializer
    init(exerciseType: ExerciseType) {
        self.exerciseType = exerciseType
        
        let concreteGrader: any ExerciseGraderProtocol
        switch exerciseType {
        case .pushup:
            concreteGrader = PushupGrader()
        case .situp:
            concreteGrader = SitupGrader()
        case .pullup:
            concreteGrader = PullupGrader()
        default:
            // Fallback for .run, .unknown, or other types not camera-based
            print("Warning: CameraExerciseView initialized with non-camera exercise type or unhandled type: \(exerciseType.displayName). Using placeholder grader.")
            concreteGrader = PlaceholderGrader()
        }
        // Initialize the StateObject with the wrapped concrete grader
        _exerciseGraderBox = StateObject(wrappedValue: AnyExerciseGraderBox(concreteGrader))
        print("CameraExerciseView initialized for \(exerciseType.displayName) using \(type(of: concreteGrader))")
    }

    var body: some View {
        ZStack {
            // Full-screen camera background
            CameraPreviewView(session: cameraService.session)
                .edgesIgnoringSafeArea(.all)

            // Overlay pose detection
            if let body = detectedBody {
                PoseOverlayView(detectedBody: body)
                    .edgesIgnoringSafeArea(.all)
            }

            // UI Overlay (Rep Counter, Feedback, Controls)
            ExerciseHUDView(
                repCount: $repCount,
                liveFeedback: $liveFeedback,
                elapsedTimeFormatted: workoutTimer.formattedElapsedTime, // Use from WorkoutTimer
                isPaused: $isWorkoutPaused, // Pass workout pause state
                isSoundEnabled: $isSoundEnabled,
                togglePauseAction: { self.toggleWorkoutPause() }, // Renamed for clarity
                toggleSoundAction: { self.toggleSound() }
            )

            // Pre-permission request view
            if showPermissionRequest {
                CameraPermissionRequestView(
                    onRequestPermission: {
                        showPermissionRequest = false
                        cameraService.requestCameraPermission()
                    },
                    onCancel: {
                        showPermissionRequest = false
                        permissionDenied = true
                        // Consider dismissing if permission is crucial and cancelled
                        // dismiss()
                    }
                )
                .zIndex(2) // Ensure it's on top
            }

            // Permission denied view
            if permissionDenied {
                permissionDeniedOverlay()
                 .zIndex(1)
            }
        }
        .onAppear(perform: setupView)
        .onDisappear(perform: cleanup)
        .navigationTitle(exerciseType.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("End") {
                    finishWorkout()
                }
                .foregroundColor(Color.red)
            }
        }
        .fullScreenCover(isPresented: $showWorkoutCompleteView) {
            WorkoutCompleteView(result: completedWorkoutResult, exerciseGrader: exerciseGraderBox)
                .onDisappear {
                    dismiss()
                }
        }
        .alert("Save Error", isPresented: $showAlertForSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage)
        }
    }

    private func setupView() {
        exerciseGraderBox.resetState()
        updateUIFromGrader()
        workoutTimer.reset()
        workoutTimer.start()
        currentWorkoutSessionID = UUID() // Generate session ID at the start
        let idStringForPrint = currentWorkoutSessionID?.uuidString ?? "nil-session-id"
        print("New workout session started with ID: \(idStringForPrint)")
        setupCameraAndPoseDetection()
    }

    private func setupCameraAndPoseDetection() {
        // Subscribe to camera authorization status
        cameraService.authorizationStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.permissionDenied = (status == .denied || status == .restricted)
                if status == .authorized {
                    self.showPermissionRequest = false
                    self.cameraService.startSession()
                    if !self.isWorkoutPaused { self.workoutTimer.resume() }
                } else if status == .notDetermined {
                    self.showPermissionRequest = true
                    self.workoutTimer.pause()
                } else {
                    self.showPermissionRequest = false
                    self.workoutTimer.stop()
                }
            }
            .store(in: &cancellables)

        // Subscribe to camera frames and pipe them to pose detector
        cameraService.framePublisher
            .compactMap { $0 } // Ensure frame is not nil
            .sink { frame in
                guard !self.isWorkoutPaused else { return } // Use isWorkoutPaused
                self.poseDetector.processFrame(frame)
            }
            .store(in: &cancellables)

        // Subscribe to detected body poses
        poseDetector.detectedBodyPublisher
            .receive(on: DispatchQueue.main)
            .sink { body in
                self.detectedBody = body
                if let detectedBody = body {
                    let result = self.exerciseGraderBox.gradePose(body: detectedBody)
                    self.handleGradingResult(result)
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to errors from services (optional but good practice)
        cameraService.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { error in print("Camera Service Error: \(error.localizedDescription)") }
            .store(in: &cancellables)

        poseDetector.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { error in print("Pose Detector Error: \(error.localizedDescription)") }
            .store(in: &cancellables)
    }

    private func cleanup() {
        cancellables.forEach { $0.cancel() }
        // timerSubscription?.cancel() // Removed
        // timerSubscription = nil // Removed
        workoutTimer.stop() // Stop the workout timer
        cameraService.stopSession()
    }

    private func handleGradingResult(_ result: GradingResult) {
        switch result {
        case .repCompleted(let formQuality):
            updateUIFromGrader()
            liveFeedback = "Rep Complete! Quality: \\(Int(formQuality * 100))%"

            if isSoundEnabled {
                AudioServicesPlaySystemSound(1104)
            }
            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.prepare()
            impactGenerator.impactOccurred()

            guard let workoutID = currentWorkoutSessionID else {
                print("Error: Workout session ID is nil. Cannot save rep data.")
                return
            }

            let repData = WorkoutDataPoint(
                // id will be generated by default
                timestamp: Date(),
                exerciseName: exerciseType.displayName,
                repNumber: self.repCount, // repCount is updated by updateUIFromGrader()
                formQuality: formQuality,
                phase: exerciseGraderBox.currentPhaseDescription,
                workoutID: workoutID // Link to the current workout session
            )
            modelContext.insert(repData)
            // SwiftData typically saves implicitly or on app background/quit.
            // Explicit save can be done here if needed, but often not necessary for each rep.
            // print("Saved rep data point: \\(repData.id) for workout \\(workoutID)")

        case .inProgress(let phase):
            liveFeedback = phase ?? exerciseGraderBox.currentPhaseDescription
        case .invalidPose(let reason):
            liveFeedback = reason
        case .incorrectForm(let feedback):
            liveFeedback = feedback
        case .noChange:
            // Optionally update phase description if it changed on grader
            liveFeedback = exerciseGraderBox.currentPhaseDescription
            break // No significant UI update needed unless phase changed
        }
        // Always update rep count from grader directly after any processing
        self.repCount = exerciseGraderBox.repCount
    }
    
    private func updateUIFromGrader() {
        self.repCount = exerciseGraderBox.repCount
        self.liveFeedback = exerciseGraderBox.currentPhaseDescription // Default feedback
        // Potentially update other UI elements based on grader state here
    }

    private func finishWorkout() {
        isWorkoutPaused = true
        workoutTimer.stop()
        
        guard let workoutID = currentWorkoutSessionID else {
            print("Error: Workout session ID is nil. Cannot finalize workout.")
            saveErrorMessage = "Workout session ID was lost. Cannot save workout."
            showAlertForSaveError = true
            self.completedWorkoutResult = nil
            self.showWorkoutCompleteView = true
            return
        }

        let finalScore = exerciseGraderBox.calculateFinalScore()
        let workoutEndTime = Date()
        let actualDuration = workoutTimer.elapsedTime
        let startTime = workoutTimer.workoutStartTime ?? workoutEndTime // Fallback for startTime

        // Use the init that doesn't take ID, then assign our pre-generated ID.
        // Also add the missing isPublic argument.
        let newResult = WorkoutResultSwiftData(
            // id: workoutID, // Don't pass ID here
            exerciseType: self.exerciseType.rawValue, 
            startTime: startTime, 
            endTime: workoutEndTime, 
            durationSeconds: actualDuration, 
            repCount: self.repCount, 
            score: finalScore,
            formQuality: exerciseGraderBox.formQualityAverage, // Add average form quality
            distanceMeters: nil, // Assuming nil for non-running exercises
            isPublic: false // Default to false, or add UI toggle later
        )
        // Assign the pre-generated session ID
        newResult.id = workoutID 
        
        modelContext.insert(newResult)
        do {
            try modelContext.save() // Explicit save for the main workout result
            self.completedWorkoutResult = newResult
            print("Workout saved successfully: \\(newResult.id)")
            self.showWorkoutCompleteView = true
        } catch {
            print("Failed to save workout: \\(error.localizedDescription)")
            self.saveErrorMessage = "Could not save your workout. Error: \\(error.localizedDescription)"
            self.showAlertForSaveError = true
            self.completedWorkoutResult = nil
            self.showWorkoutCompleteView = true 
        }
    }

    // MARK: - Timer Control - REMOVED, MOVED TO WorkoutTimer
    /*
    private func startTimer() {
        guard !isPaused else { return }
        if workoutStartTime == nil {
            workoutStartTime = Date() // Set start time only once
        }
        timerSubscription?.cancel() // Cancel any existing timer
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { _ in
            elapsedTime += 1
        }
    }

    private func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }
    */

    private func toggleWorkoutPause() { // Renamed from togglePause
        isWorkoutPaused.toggle()
        if isWorkoutPaused {
            // stopTimer()
            workoutTimer.pause()
            liveFeedback = "Paused"
        } else {
            // startTimer()
            workoutTimer.resume()
            updateUIFromGrader() // Refresh feedback
        }
    }

    private func toggleSound() {
        isSoundEnabled.toggle()
        // Future: May need to inform the grader or other audio components
    }

    // MARK: - UI Subviews
    /*
    @ViewBuilder
    private func exerciseOverlayUI() -> some View {
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
                    Text(formatTime(elapsedTime))
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
                Button { togglePause() } label: {
                    Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(Color.white) // TODO: Replace with correct design system color AppTheme.GeneratedColors.textPrimaryOnDark
                }

                Button {
                    isSoundEnabled.toggle()
                    // TODO: Implement sound muting logic for grader audio cues
                } label: {
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
    */
    
    // formatTime will be kept here as it's used by ExerciseHUDView via a property
    /*
    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    */
    
    @ViewBuilder
    private func permissionDeniedOverlay() -> some View {
        VStack(spacing: AppTheme.GeneratedSpacing.medium) {
            Image(systemName: "camera.slash.fill")
                .font(.system(size: 50))
                .foregroundColor(Color.white) // TODO: Replace with correct design system color AppTheme.GeneratedColors.textPrimaryOnDark
            PTLabel("Camera Access Denied", style: .heading)
            PTLabel("This feature requires camera access to track exercises. Please enable camera access in Settings.", style: .body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            PTButton("Open Settings", style: .primary) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
        .padding(AppTheme.GeneratedSpacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.85).edgesIgnoringSafeArea(.all)) // TODO: Replace with correct design system color AppTheme.GeneratedColors.backgroundOverlay.edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Preview
struct CameraExerciseView_Previews: PreviewProvider {
    static var previews: some View {
        // Ensure ExerciseType is available or use a mock for preview
        // For this example, assuming ExerciseType.pushup is valid.
        // If not, replace with a mock or a concrete existing type.
        // This preview might still fail if ExerciseType and its properties aren't fully resolved.
        NavigationView {
            // CameraExerciseView(exerciseType: ExerciseType.pushup) // Use actual ExerciseType if available
            Text("Preview requires ExerciseType.pushup or similar to be defined and accessible.")
        }
    }
}

// Preview requires ExerciseType to be available
// You might need to define a mock or ensure it's part of PTDesignSystem for previews
#if DEBUG
enum PreviewExerciseType: String, CaseIterable, ExerciseTypeProtocol {
    case pushup, situp
    var rawValue: String { self.string }
    var string: String {
        switch self {
        case .pushup: return "pushup"
        case .situp: return "situp"
        }
    }
    var displayName: String { self.string.capitalized }
    // Add other ExerciseTypeProtocol requirements if any for previewing
}

protocol ExerciseTypeProtocol {
    var rawValue: String { get }
    var displayName: String { get }
}
#endif 