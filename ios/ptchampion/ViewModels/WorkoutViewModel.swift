import Foundation
import Combine
import AVFoundation // For AVAuthorizationStatus
import SwiftData // Import SwiftData
import SwiftUI // Import SwiftUI for potential @AppStorage use later if needed
import Vision // For VNHumanBodyPoseObservation

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
    @Published var formScore: Double = 0.0
    @Published var badJointNames: Set<VNHumanBodyPoseObservation.JointName> = []
    @Published var poseFrameIndex: Int = 0 // For efficient redraws of pose overlay
    
    // Rep counter update publisher - emits once per completed rep
    private let repCompletedSubject = PassthroughSubject<Int, Never>()
    var repCompletedPublisher: AnyPublisher<Int, Never> {
        repCompletedSubject.eraseToAnyPublisher()
    }

    // Internal State for Timer
    private var workoutStartDate: Date?
    private var timerSubscription: AnyCancellable?
    private var accumulatedTime: TimeInterval = 0
    private var isTimerRunning: Bool = false
    
    // State for tracking body detection loss
    private var consecutiveFramesWithoutBody: Int = 0
    private let maxFramesWithoutBody = 10 // Threshold before showing visibility warning
    
    // Frame rate calculation for stable frames
    private var frameCounter: Int = 0
    private var lastFPSCalculationTime: TimeInterval = 0
    private var currentFPS: Double = 30.0 // Default 30fps assumption
    
    // Status for body detection
    private enum BodyDetectionStatus {
        case detected      // Body is detected with good confidence
        case lowConfidence // Body detected but with low confidence
        case notVisible    // Body not visible in frame
    }
    private var bodyDetectionStatus: BodyDetectionStatus = .notVisible

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
        
        // Register for orientation changes
        setupOrientationNotification()
    }
    
    // Setup orientation observer
    private func setupOrientationNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceOrientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    // Handle orientation changes
    @objc private func deviceOrientationDidChange() {
        // Use a slight delay to ensure the interface has updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let cameraService = self?._cameraService as? CameraService else { return }
            cameraService.updateOutputOrientation()
        }
    }
    
    // Release camera resources
    func releaseCamera() {
        print("Releasing CameraService resources")
        _cameraService?.stopSession()
        _cameraService = nil
        cancellables.removeAll()
        
        // Remove orientation observer
        NotificationCenter.default.removeObserver(
            self,
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
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
                 guard let self = self, self.workoutState == .counting else { return } // Only process if counting
                 
                 // Track FPS for stable frame calculations
                 self.frameCounter += 1
                 let now = CACurrentMediaTime()
                 if now - self.lastFPSCalculationTime > 1.0 { // Calculate FPS every second
                     self.currentFPS = Double(self.frameCounter) / (now - self.lastFPSCalculationTime)
                     self.frameCounter = 0
                     self.lastFPSCalculationTime = now
                 }
                 
                 self.poseDetectorService.processFrame(frameBuffer)
            }
            .store(in: &cancellables)

        // Subscribe to Detected Poses -> Grade Exercise
        poseDetectorService.detectedBodyPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] detectedBody in
                guard let self = self else { return }
                self.detectedBody = detectedBody
                self.updateBodyDetectionStatus(detectedBody)
                
                if self.workoutState == .counting {
                    if let body = detectedBody, self.bodyDetectionStatus == .detected {
                        // Reset counter when body detected
                        self.consecutiveFramesWithoutBody = 0
                        // Grade the frame
                        self.gradeFrame(body: body)
                    } else {
                        // Handle body not detected during workout
                        self.handleBodyNotDetected()
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
    
    // Determine if the body detection is good enough to use for grading
    private func updateBodyDetectionStatus(_ body: DetectedBody?) {
        guard let body = body else {
            bodyDetectionStatus = .notVisible
            return
        }
        
        // Check overall confidence and key joint availability
        let keyJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist,
            .leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle
        ]
        
        // Check if at least 80% of key joints are detected with reasonable confidence
        let detectedKeyJoints = keyJoints.filter { jointName in
            guard let point = body.point(jointName) else { return false }
            return point.confidence > 0.3 // Lower threshold for status check vs. actual grading
        }
        
        let detectionRatio = Double(detectedKeyJoints.count) / Double(keyJoints.count)
        
        if detectionRatio >= 0.8 && body.confidence > 0.5 {
            bodyDetectionStatus = .detected
        } else if detectionRatio >= 0.6 && body.confidence > 0.3 {
            bodyDetectionStatus = .lowConfidence
        } else {
            bodyDetectionStatus = .notVisible
        }
    }
    
    // Handle situations where body isn't detected well enough for grading
    private func handleBodyNotDetected() {
        consecutiveFramesWithoutBody += 1
        
        // Only show message after several consecutive frames without detection
        if consecutiveFramesWithoutBody > maxFramesWithoutBody {
            switch bodyDetectionStatus {
            case .lowConfidence:
                feedbackMessage = "Low visibility. Move under better lighting."
            case .notVisible:
                feedbackMessage = "Body not detected. Ensure full body is visible."
            case .detected:
                // Should not reach here
                break
            }
        }
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
        if let startDate = workoutStartDate {
            accumulatedTime += Date().timeIntervalSince(startDate)
            workoutStartDate = nil
        }
        timerSubscription?.cancel()
        timerSubscription = nil
    }

    private func stopTimer() {
        isTimerRunning = false
        timerSubscription?.cancel()
        timerSubscription = nil
        // Reset for next workout
        accumulatedTime = 0
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
        formScore = 0.0
        consecutiveFramesWithoutBody = 0
        
        // Reset time tracking
        if workoutState != .paused {  // If starting fresh (not resuming)
            accumulatedTime = 0       // Reset accumulated time
            workoutStartDate = Date() // Set new start time
        } else {
            workoutStartDate = Date() // Set new segment start time
        }
        
        feedbackMessage = "Starting... Get ready!"
        workoutState = .counting
        startTimer()
        
        // Reset FPS tracking with workout start
        frameCounter = 0
        lastFPSCalculationTime = CACurrentMediaTime()
        
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

        // Capture final stats
        let endTime = Date()
        var duration: TimeInterval = 0
        
        if let startDate = workoutStartDate, workoutState == .counting {
            // For active workout, add current segment to accumulated
            duration = accumulatedTime + endTime.timeIntervalSince(startDate)
        } else {
            // For paused workout, use accumulated time
            duration = accumulatedTime
        }
        
        let finalRepCount = self.repCount
        let finalScore = exerciseGrader.calculateFinalScore()
        let formQuality = exerciseGrader.formQualityAverage * 100
        self.formScore = formQuality

        // Stop processes
        pauseTimer() // Stop timer updates first
        stopCamera() // Stop camera session
        workoutState = .finished
        feedbackMessage = "Workout Complete! Reps: \(finalRepCount)" // Update feedback
        updateTimerDisplay(duration) // Show final time
        print("WorkoutViewModel: Workout finished. Duration: \(Int(duration))s, Reps: \(finalRepCount), Score: \(finalScore ?? -1), Form: \(formQuality)")

        // Save result using SwiftData
        saveResultLocally(startTime: workoutStartDate ?? endTime,
                          endTime: endTime,
                          duration: Int(duration),
                          reps: finalRepCount,
                          score: finalScore,
                          formQuality: formQuality)

        // Reset internal state
        stopTimer() // Fully reset timer state
        repCount = 0
        exerciseGrader.resetState()
    }

    // MARK: - Grading Logic (Uses ExerciseGrader)

    private func gradeFrame(body: DetectedBody) {
        guard workoutState == .counting else { return }

        let result = exerciseGrader.gradePose(body: body)
        poseFrameIndex += 1 // Increment frame index for efficient Canvas redraws
        
        // Clear bad joints by default
        badJointNames = []

        switch result {
        case .repCompleted(let formQuality):
            // Update rep count
            repCount += 1
            
            // Emit event for UI animation
            repCompletedSubject.send(repCount)
            
            // Update feedback with color-coded message
            if formQuality > 0.9 {
                feedbackMessage = "✅ Perfect form! (\(repCount))"
            } else if formQuality > 0.7 {
                feedbackMessage = "✅ Good rep! (\(repCount))"
            } else {
                feedbackMessage = "⚠️ Rep counted! Check form. (\(repCount))"
            }
            
            // Optional: Play haptic feedback for completed rep
            playHapticFeedback(.success)
            
        case .inProgress(let phase):
            // Use phase info if provided by grader
            if let phase = phase {
                feedbackMessage = phase
            }
            
        case .invalidPose(let reason):
            feedbackMessage = "⚠️ Adjust: \(reason)"
            
        case .incorrectForm(let feedback):
            feedbackMessage = "⚠️ \(feedback)"
            
            // Get bad joints from the grader and update the published property
            if let grader = exerciseGrader as? PushupGrader {
                badJointNames = grader.problemJoints
            } else if let grader = exerciseGrader as? SitupGrader {
                badJointNames = grader.problemJoints
            } else if let grader = exerciseGrader as? PullupGrader {
                badJointNames = grader.problemJoints
            }
            
            // Subtle haptic feedback for form correction
            playHapticFeedback(.warning)
            
        case .noChange:
            // Keep previous feedback
            break
        }
        
        // Update current form score from grader (0-100)
        formScore = exerciseGrader.formQualityAverage * 100
    }

    // MARK: - Data Saving

    private func saveResultLocally(
        startTime: Date, 
        endTime: Date, 
        duration: Int, 
        reps: Int, 
        score: Double?,
        formQuality: Double
    ) {
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
            formQuality: formQuality,
            distanceMeters: nil // Not applicable for pose workouts
        )

        context.insert(resultData)

        do {
            try context.save()
            print("WorkoutViewModel: Workout saved locally successfully!")
            
            // Save to server if possible
            Task {
                await saveWorkoutToServer(
                    exerciseType: exerciseType,
                    duration: duration,
                    reps: reps,
                    formQuality: formQuality,
                    score: score
                )
            }
        } catch {
            print("WorkoutViewModel: Failed to save workout locally: \(error.localizedDescription)")
            errorMessage = "Failed to save workout data locally."
        }
    }
    
    // Save workout to server
    private func saveWorkoutToServer(
        exerciseType: WorkoutExerciseType, 
        duration: Int, 
        reps: Int, 
        formQuality: Double, 
        score: Double?
    ) async {
        guard let userId = keychainService.getUserID() else {
            print("WorkoutViewModel: Cannot save to server - user ID not found")
            return
        }
        
        // Get auth token
        guard let authToken = keychainService.getAccessToken() else {
            print("WorkoutViewModel: Cannot save to server - no auth token")
            return
        }
        
        // Determine exercise ID based on type
        let exerciseId: Int
        switch exerciseType {
        case .pushup: exerciseId = 1
        case .situp: exerciseId = 2
        case .pullup: exerciseId = 3
        case .run: exerciseId = 4
        case .unknown: exerciseId = 0
        }
        
        // Skip for unknown exercise
        guard exerciseId > 0 else { return }
        
        // Create metadata with additional info
        let metadataDict: [String: Any] = [
            "form_quality": formQuality,
            "device_type": "iOS",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        ]
        
        let metadataString = try? JSONSerialization.data(withJSONObject: metadataDict)
            .base64EncodedString()
        
        let workout = InsertUserExerciseRequest(
            userId: Int(userId) ?? 0,
            exerciseId: exerciseId,
            repetitions: reps > 0 ? reps : nil,
            formScore: Int(formQuality),
            timeInSeconds: duration,
            grade: score.map { Int($0) },
            completed: true,
            metadata: metadataString,
            deviceId: UIDevice.current.identifierForVendor?.uuidString,
            syncStatus: "app" // Add sync status
        )
        
        do {
            // Call workoutService.saveWorkout with the correct parameter names
            try await workoutService.saveWorkout(result: workout, authToken: authToken)
            print("WorkoutViewModel: Workout saved to server successfully!")
        } catch {
            print("WorkoutViewModel: Failed to save workout to server: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers
    
    // Haptic feedback
    private func playHapticFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    // MARK: - Cleanup
    deinit {
        // 1. take a local strong ref while `self` is still valid
        let service = _cameraService

        // 2. stop the session asynchronously without touching `self`
        if let service {
            Task.detached {
                service.stopSession()
            }
        }

        timerSubscription?.cancel()
        cancellables.removeAll()
        print("WorkoutViewModel for \(exerciseName) deinitialized.")
    }
}

// Simple No-Operation Grader for unknown exercises
class NoOpGrader: ExerciseGraderProtocol {
    static var targetFramesPerSecond: Double = 30.0
    static var requiredJointConfidence: Float = 0.5
    static var requiredStableFrames: Int = 5
    
    var currentPhaseDescription: String { "N/A" }
    var repCount: Int { 0 }
    var formQualityAverage: Double { 0.0 }
    var lastFormIssue: String? { nil }
    
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