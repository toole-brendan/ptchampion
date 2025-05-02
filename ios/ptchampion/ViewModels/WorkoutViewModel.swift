import Foundation
import Combine
import AVFoundation // For AVAuthorizationStatus
import SwiftData // Import SwiftData
import SwiftUI // Import SwiftUI for potential @AppStorage use later if needed

// Define exercise type enum within the file scope to avoid ambiguity
enum WorkoutExerciseType: String {
    case pushup = "Push-ups"
    case situp = "Sit-ups" 
    case pullup = "Pull-ups"
    case run = "Run"
    case unknown = "Unknown"

    init(key: String) {
        self = WorkoutExerciseType(rawValue: key) ?? .unknown
    }
}

@MainActor
class WorkoutViewModel: ObservableObject {

    // Make cameraService optional and lazily initialized
    private var _cameraService: CameraServiceProtocol?
    var cameraService: CameraServiceProtocol? {
        return _cameraService
    }
    
    private let poseDetectorService: PoseDetectorServiceProtocol
    private let exerciseGrader: ExerciseGraderProtocol
    private let workoutService: WorkoutServiceProtocol
    private let keychainService: KeychainServiceProtocol
    var modelContext: ModelContext? // Change from private to internal

    private var cancellables = Set<AnyCancellable>()

    // Input
    let exerciseName: String
    private var exerciseType: WorkoutExerciseType { WorkoutExerciseType(key: exerciseName) }

    // Published State for UI
    @Published var cameraAuthorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var detectedBody: DetectedBody? = nil
    @Published var repCount: Int = 0
    @Published var feedbackMessage: String = "Position yourself in the frame."
    @Published var workoutState: WorkoutState = .initializing
    @Published var errorMessage: String? = nil
    @Published var elapsedTimeFormatted: String = "00:00"

    // Internal State for Timer
    private var workoutStartDate: Date?
    private var timerSubscription: AnyCancellable?
    private var accumulatedTime: TimeInterval = 0
    private var isTimerRunning: Bool = false

    // Represents the state of the workout session
    enum WorkoutState: Equatable {
        case initializing
        case requestingPermission
        case permissionDenied
        case ready // Camera ready, waiting to start
        case counting
        case paused
        case finished
        case error(String)
        
        // Implement Equatable manually since the enum has associated values
        static func == (lhs: WorkoutState, rhs: WorkoutState) -> Bool {
            switch (lhs, rhs) {
            case (.initializing, .initializing),
                 (.requestingPermission, .requestingPermission),
                 (.permissionDenied, .permissionDenied),
                 (.ready, .ready),
                 (.counting, .counting),
                 (.paused, .paused),
                 (.finished, .finished):
                return true
            case (.error(let lhsMsg), .error(let rhsMsg)):
                return lhsMsg == rhsMsg
            default:
                return false
            }
        }
    }

    init(exerciseName: String,
         poseDetectorService: PoseDetectorServiceProtocol = PoseDetectorService(),
         exerciseGrader: ExerciseGraderProtocol? = nil,
         workoutService: WorkoutServiceProtocol = WorkoutService(),
         keychainService: KeychainServiceProtocol = KeychainService(),
         modelContext: ModelContext? = nil // Add modelContext parameter
    ) {
        self.exerciseName = exerciseName
        self.poseDetectorService = poseDetectorService
        self.workoutService = workoutService
        self.keychainService = keychainService
        self.modelContext = modelContext // Assign modelContext

        // Select the appropriate grader based on exercise name
        if let providedGrader = exerciseGrader {
            self.exerciseGrader = providedGrader
        } else {
             switch WorkoutExerciseType(key: exerciseName) { // Use enum for switch
             case .pushup:
                 self.exerciseGrader = PushupGrader()
             case .situp:
                 self.exerciseGrader = SitupGrader()
             case .pullup:
                 self.exerciseGrader = PullupGrader()
             case .run, .unknown:
                 print("Warning: No specific pose grader for \(exerciseName). Using NoOpGrader.")
                 self.exerciseGrader = NoOpGrader()
             // Handle other cases explicitly if needed
             }
        }

        print("WorkoutViewModel initialized for \(exerciseName) using \(type(of: self.exerciseGrader))")
        checkInitialCameraPermission()
    }
    
    // Initialize the camera service on demand
    func initializeCamera() {
        guard _cameraService == nil else {
            print("CameraService already initialized")
            return
        }
        
        print("Initializing new CameraService")
        _cameraService = CameraService()
        subscribeToServices()
    }
    
    // Release camera resources
    func releaseCamera() {
        print("Releasing CameraService resources")
        _cameraService = nil
        cancellables.removeAll()
    }

    private func subscribeToServices() {
        guard let cameraService = _cameraService else {
            print("Cannot subscribe to services - CameraService not initialized")
            return
        }
        
        // Subscribe to Camera Authorization Status
        cameraService.authorizationStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.cameraAuthorizationStatus = status
                self?.handleAuthorizationStatusChange(status)
            }
            .store(in: &cancellables)

        // Subscribe to Camera Frames -> Process with Pose Detector
        cameraService.framePublisher
            .sink { [weak self] frameBuffer in
                 guard self?.workoutState == .counting else { return } // Only process if counting
                 self?.poseDetectorService.processFrame(frameBuffer)
            }
            .store(in: &cancellables)

        // Subscribe to Detected Poses -> Grade Exercise
        poseDetectorService.detectedBodyPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] detectedBody in
                self?.detectedBody = detectedBody
                if let body = detectedBody {
                    self?.gradeFrame(body: body)
                } else {
                    // Handle case where body is lost during counting
                    if self?.workoutState == .counting {
                       // self?.feedbackMessage = "Body not detected. Ensure you are fully in frame."
                    }
                }
            }
            .store(in: &cancellables)

        // Subscribe to Errors from Camera
        cameraService.errorPublisher
             .receive(on: DispatchQueue.main)
             .sink { [weak self] error in
                 print("WorkoutViewModel: Camera Service Error: \(error.localizedDescription)")
                 self?.errorMessage = "Camera Error: \(error.localizedDescription)"
                 self?.workoutState = .error(error.localizedDescription)
                 self?.stopWorkout()
             }
             .store(in: &cancellables)

         // Subscribe to Errors from Pose Detector
         poseDetectorService.errorPublisher
             .receive(on: DispatchQueue.main)
             .sink { [weak self] error in
                 print("WorkoutViewModel: Pose Detector Error: \(error.localizedDescription)")
                 // Decide if this error should stop the workout or just be informational
                 self?.errorMessage = "Pose Detection Error: \(error.localizedDescription)"
                 // Potentially revert to a state where user needs to reposition
             }
             .store(in: &cancellables)
    }

    private func checkInitialCameraPermission() {
         let status = AVCaptureDevice.authorizationStatus(for: .video)
         handleAuthorizationStatusChange(status)
    }

    private func handleAuthorizationStatusChange(_ status: AVAuthorizationStatus) {
         switch status {
         case .authorized:
             workoutState = .ready
             // Don't start camera here - wait for explicit call
         case .notDetermined:
             workoutState = .requestingPermission
             _cameraService?.requestCameraPermission()
         case .denied, .restricted:
             workoutState = .permissionDenied
             errorMessage = "Camera access is required. Please enable it in Settings."
         @unknown default:
             workoutState = .error("Unknown camera authorization status.")
             errorMessage = "An unknown error occurred with camera permissions."
         }
     }

    func startCamera() {
        guard cameraAuthorizationStatus == .authorized else { return }
        _cameraService?.startSession()
        print("WorkoutViewModel: Camera session started.")
    }

    func stopCamera() {
        _cameraService?.stopSession()
        print("WorkoutViewModel: Camera session stopped.")
    }

    // MARK: - Timer Logic

    private func startTimer() {
        guard !isTimerRunning else { return }
        if workoutStartDate == nil {
            workoutStartDate = Date() // Set start time only once
        }
        let resumeDate = Date()
        isTimerRunning = true

        timerSubscription = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
            .sink { [weak self] firedDate in
                guard let self = self, self.isTimerRunning else { return }
                // Calculate total elapsed time including pauses
                let currentTime = firedDate.timeIntervalSince(resumeDate)
                let totalElapsed = self.accumulatedTime + currentTime
                self.updateTimerDisplay(totalElapsed)
            }
    }

    private func pauseTimer() {
        guard isTimerRunning else { return }
        isTimerRunning = false
        // Calculate time elapsed since last resume and add to accumulated time
        timerSubscription?.cancel()
        timerSubscription = nil
    }

    private func stopTimer() {
        isTimerRunning = false
        timerSubscription?.cancel()
        timerSubscription = nil
        // Calculate final accumulated time
        accumulatedTime = 0 // Reset for next workout
        workoutStartDate = nil
        updateTimerDisplay(0)
    }

    private func updateTimerDisplay(_ timeInterval: TimeInterval) {
        let totalSeconds = Int(timeInterval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        elapsedTimeFormatted = String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Workout Control

    func startWorkout() {
        guard workoutState == .ready || workoutState == .paused else { return }
        exerciseGrader.resetState()
        repCount = 0
        accumulatedTime = 0 // Reset timer state
        workoutStartDate = Date() // Set start time
        feedbackMessage = "Starting... Get ready!"
        workoutState = .counting
        startTimer()
        print("WorkoutViewModel: Workout started.")
    }

    func pauseWorkout() {
        guard workoutState == .counting else { return }
        workoutState = .paused
        feedbackMessage = "Workout Paused"
        pauseTimer()
        print("WorkoutViewModel: Workout paused.")
    }

    func resumeWorkout() {
        guard workoutState == .paused else { return }
        workoutState = .counting
        feedbackMessage = "Resuming..."
        startTimer() // Restarts timer publisher
        print("WorkoutViewModel: Workout resumed.")
    }

    func stopWorkout() {
        guard workoutState == .counting || workoutState == .paused else { return }

        let endTime = Date()
        let duration = workoutStartDate.map { endTime.timeIntervalSince($0) } ?? 0
        let finalRepCount = self.repCount
        let finalScore = exerciseGrader.calculateFinalScore() // Assume grader provides score

        // Stop processes
        pauseTimer() // Stop timer updates first
        stopCamera() // Stop camera session
        workoutState = .finished
        feedbackMessage = "Workout Complete! Reps: \(finalRepCount)" // Update feedback
        updateTimerDisplay(duration) // Show final time
        print("WorkoutViewModel: Workout finished. Duration: \(Int(duration))s, Reps: \(finalRepCount), Score: \(finalScore ?? -1)")

        // Save result using SwiftData
        saveResultLocally(startTime: workoutStartDate ?? endTime,
                           endTime: endTime,
                           duration: Int(duration),
                           reps: finalRepCount,
                           score: finalScore)

        // Reset internal state
        stopTimer() // Fully reset timer state
        repCount = 0
        exerciseGrader.resetState()
    }

    // MARK: - Grading Logic (Now uses ExerciseGrader)

    private func gradeFrame(body: DetectedBody) {
        guard workoutState == .counting else { return }

        let result = exerciseGrader.gradePose(body: body)

        switch result {
        case .repCompleted:
            repCount += 1
            feedbackMessage = "Good Rep! (\(repCount))"
        case .inProgress(let phase):
            // Use phase info if provided by grader, otherwise default message
            feedbackMessage = phase ?? "Keep going..."
        case .invalidPose(let reason):
            feedbackMessage = "Adjust: \(reason)"
        case .incorrectForm(let feedback):
            feedbackMessage = "Form: \(feedback)"
        case .noChange:
            // Keep previous feedback or provide generic message
            break // Don't necessarily update feedback message every frame
        }
    }

    // MARK: - Data Saving (SwiftData)

    private func saveResultLocally(startTime: Date, endTime: Date, duration: Int, reps: Int, score: Double?) {
        guard duration > 0 || reps > 0 else {
            print("WorkoutViewModel: Skipping save for zero duration/reps workout.")
            return
        }

        guard let context = modelContext else {
            print("WorkoutViewModel: ModelContext not available. Cannot save workout locally.")
            errorMessage = "Internal error: Could not save workout data."
            return
        }

        let resultData = WorkoutResultSwiftData(
            exerciseType: exerciseType.rawValue,
            startTime: startTime,
            endTime: endTime,
            durationSeconds: duration,
            repCount: reps,
            score: score,
            distanceMeters: nil // Not applicable for pose workouts
        )

        context.insert(resultData)

        do {
            try context.save()
            print("WorkoutViewModel: Workout saved locally successfully!")
        } catch {
            print("WorkoutViewModel: Failed to save workout locally: \(error.localizedDescription)")
            errorMessage = "Failed to save workout data locally."
        }
    }

    // MARK: - Cleanup
    deinit {
        // Ensure resources are released
        Task { @MainActor in
            stopCamera()
        }
        timerSubscription?.cancel()
        print("WorkoutViewModel for \(exerciseName) deinitialized.")
    }
}

// Simple No-Operation Grader for unknown exercises
class NoOpGrader: ExerciseGraderProtocol {
    var currentPhaseDescription: String { "N/A" }
    func resetState() {}
    func gradePose(body: DetectedBody) -> GradingResult {
        return .noChange
    }
    func calculateFinalScore() -> Double? {
        return nil // No score for no-op grader
    }
}

// TODO: Implement haptic feedback helper if desired
// import UIKit
// func playHapticFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
//     let generator = UINotificationFeedbackGenerator()
//     generator.notificationOccurred(type)
// }

// Helper Extension for ExerciseType (if not defined elsewhere)
// Consider moving this to a shared Enums file
/*
enum ExerciseType: String {
    case pushups = "Push-ups"
    case situps = "Sit-ups"
    case pullups = "Pull-ups"
    case run = "Run"
    case unknown = "Unknown"

    init(displayName: String) {
        self = ExerciseType(rawValue: displayName) ?? .unknown
    }

    // Add iconName property if needed here or in the original Enum file
}
*/ 