import SwiftUI
import Combine
import AVFoundation // For AVAuthorizationStatus
import SwiftData
import Vision // For VNHumanBodyPoseObservation.JointName

// Assuming ExerciseType is defined in Models/WorkoutModels.swift and is accessible globally in the target
// For example:
// enum ExerciseType: String, Codable, CaseIterable, Identifiable {
//     case pushup = "pushup", situp = "situp", pullup = "pullup", run = "run", unknown = "unknown"
//     var id: String { self.rawValue }
//     var displayName: String { /* ... */ }
// }

// Assuming GradingResult and DetectedBody are defined elsewhere (e.g., Grading/ and Models/)

// Moved WorkoutState enum outside the class definition
enum WorkoutState: Equatable {
    case initializing
    case requestingPermission
    case permissionDenied
    case ready // Camera ready, waiting to start
    case counting
    case paused
    case finished
    case error(String)
    
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

@MainActor
class WorkoutViewModel: ObservableObject {

    // MARK: - Published Properties for UI
    @Published var selectedExercise: ExerciseType
    @Published var repCount: Int = 0
    @Published var sets: Int = 0 // For manual entry or future plans
    @Published var weight: Double = 0 // For manual entry or future plans
    @Published var notes: String = "" // For manual entry or future plans

    @Published var isWorkoutActive: Bool = false
    @Published var workoutStartTime: Date? = nil
    @Published var elapsedTimeFormatted: String = "00:00"

    @Published var feedbackMessage: String = "Select an exercise to begin."
    @Published var formScore: Double? = nil // Overall score, 0-100
    @Published var currentPhase: String? = nil
    @Published var problemJoints: Set<VNHumanBodyPoseObservation.JointName> = []

    @Published var cameraAuthorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var detectedBody: DetectedBody? = nil // For pose overlay rendering
    @Published var workoutState: WorkoutState = .initializing
    @Published var errorMessage: String? = nil
    @Published var isCameraPermissionGranted: Bool = false
    @Published var badJointNames: Set<VNHumanBodyPoseObservation.JointName> = []
    @Published var poseFrameIndex: Int = 0 // Or UUID, if preferred for uniqueness


    // MARK: - Services and Grader
    private var _cameraService: CameraServiceProtocol? // Lazily initialized
    var cameraService: CameraServiceProtocol? { _cameraService } // Read-only public access

    private let poseDetectorService: PoseDetectorServiceProtocol
    private var exerciseGrader: any ExerciseGraderProtocol // Instance of a concrete grader
    private let workoutService: WorkoutServiceProtocol
    private let keychainService: KeychainServiceProtocol
    var modelContext: ModelContext? // For saving data

    // MARK: - Internal State
    private var exerciseName: String // From init
    private var cancellables = Set<AnyCancellable>()

    // Timer
    private var timerSubscription: AnyCancellable?
    private var accumulatedTime: TimeInterval = 0
    private var isTimerRunning: Bool = false
    
    // Body Detection Tracking
    private var consecutiveFramesWithoutBody: Int = 0
    private let maxFramesWithoutBodyBeforeWarning = 15 // e.g., 0.5 seconds at 30fps

    // MARK: - Publishers
    let repCompletedPublisher = PassthroughSubject<Void, Never>()

    // MARK: - Initialization
    init(
        exerciseName: String, // Typically corresponds to ExerciseType.rawValue
        poseDetectorService: PoseDetectorServiceProtocol = PoseDetectorService(),
        exerciseGrader: (any ExerciseGraderProtocol)? = nil, // Allow injecting for testing/specifics
        workoutService: WorkoutServiceProtocol = WorkoutService(),
        keychainService: KeychainServiceProtocol = KeychainService(),
        modelContext: ModelContext? = nil
    ) {
        self.exerciseName = exerciseName
        self.poseDetectorService = poseDetectorService
        self.workoutService = workoutService
        self.keychainService = keychainService
        self.modelContext = modelContext

        // Phase 1: Initialize all stored properties
        let resolvedExerciseType = ExerciseType(rawValue: exerciseName.lowercased()) ?? .unknown
        self.selectedExercise = resolvedExerciseType

        if let providedGrader = exerciseGrader {
            self.exerciseGrader = providedGrader
        } else {
            self.exerciseGrader = Self.grader(for: resolvedExerciseType)
        }
        // All properties are now initialized.

        // Phase 2: `self` is fully available.
        print("WorkoutViewModel initialized for \(exerciseName) using \(type(of: self.exerciseGrader))")
        
        // Initialize UI-related properties from grader's initial state
        updateUIFromGraderState()
        self.feedbackMessage = "Ready for \(resolvedExerciseType.displayName)."
        
        checkInitialCameraPermission() // Check current permission status
        setupSubscribers()             // Set up Combine subscriptions
    }

    deinit {
        DispatchQueue.main.async { [weak self] in // Add weak self to avoid retain cycles if self is captured
            self?.releaseCamera() // Ensure camera resources are freed
        }
        cancellables.forEach { $0.cancel() }
        timerSubscription?.cancel()
        print("WorkoutViewModel for \(exerciseName) deinitialized.")
    }

    // MARK: - Camera Service Management
    func initializeCamera() {
        guard _cameraService == nil else { return }
        print("WorkoutViewModel: Initializing CameraService.")
        _cameraService = CameraService()
        subscribeToCameraServices() // Specific subscriptions for camera
        setupOrientationNotification()
        if cameraAuthorizationStatus == .authorized {
             _cameraService?.startSession()
        }
    }

    func releaseCamera() {
        print("WorkoutViewModel: Releasing CameraService.")
        _cameraService?.stopSession()
        _cameraService = nil // Allows re-initialization
        // Specific camera/pose detector cancellables might be managed separately if needed
        // For simplicity, `cancellables.removeAll()` in deinit handles general ones.
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    private func setupOrientationNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceOrientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    @objc private func deviceOrientationDidChange() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in // Increased delay slightly
            (self?._cameraService as? CameraService)?.updateOutputOrientation()
        }
    }

    func startCamera() {
        print("WorkoutViewModel: Starting camera session.")
        _cameraService?.startSession()
    }

    func stopCamera() {
        print("WorkoutViewModel: Stopping camera session.")
        _cameraService?.stopSession()
    }

    // MARK: - Subscriptions
    private func setupSubscribers() {
        // React to changes in selected exercise type
        $selectedExercise
            .dropFirst() // Ignore initial value
            .sink { [weak self] newExerciseType in
                self?.updateGrader(for: newExerciseType)
            }
            .store(in: &cancellables)
    }

    private func subscribeToCameraServices() {
        guard let cameraService = _cameraService else { return }

        cameraService.authorizationStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.cameraAuthorizationStatus = status
                self?.handleAuthorizationStatusChange(status)
            }
            .store(in: &cancellables)

        cameraService.framePublisher
            .compactMap { $0 } // Ensure frame is not nil
            .sink { [weak self] frameBuffer in
                guard let self = self, self.workoutState == .counting, self.isTimerRunning else { return }
                self.poseDetectorService.processFrame(frameBuffer)
            }
            .store(in: &cancellables)

        poseDetectorService.detectedBodyPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] detectedBody in
                guard let self = self else { return }
                self.detectedBody = detectedBody
                
                if let body = detectedBody, body.confidence > (type(of: self.exerciseGrader).requiredJointConfidence * 0.8) { 
                    self.consecutiveFramesWithoutBody = 0
                    if self.workoutState == .counting {
                        self.gradeFrame(body: body)
                        self.poseFrameIndex += 1 // Increment to trigger UI updates for pose
                    }
                } else {
                    self.consecutiveFramesWithoutBody += 1
                    if self.consecutiveFramesWithoutBody > self.maxFramesWithoutBodyBeforeWarning && self.workoutState == .counting {
                        self.feedbackMessage = "Body not clearly visible. Adjust position."
                        // No need to update problemJoints here as it's a visibility issue
                    }
                }
            }
            .store(in: &cancellables)
        
        cameraService.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                 self?.handleServiceError(error, serviceName: "Camera")
            }
            .store(in: &cancellables)

        poseDetectorService.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.handleServiceError(error, serviceName: "Pose Detector")
            }
            .store(in: &cancellables)
    }
    
    private func handleServiceError(_ error: Error, serviceName: String) {
        print("WorkoutViewModel: \(serviceName) Error: \(error.localizedDescription)")
        self.errorMessage = "\(serviceName) Error: \(error.localizedDescription)"
        // Optionally change workoutState to .error only for critical camera errors
        if serviceName == "Camera" {
            self.workoutState = .error("A \(serviceName.lowercased()) error occurred.")
            self.stopWorkoutFlow(saveAttempt: false) // Stop without saving if camera fails critically
        }
    }

    // MARK: - Permissions
    private func checkInitialCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        handleAuthorizationStatusChange(status)
    }

    func requestCameraAccess() { // Public method for View to call
        guard let cameraService = _cameraService else {
            initializeCamera() // Ensure camera service is there to request
            // If it's still nil after this, something is wrong
            if _cameraService == nil {
                 self.workoutState = .error("Camera system not available.")
                 return
            }
            // Retry request after short delay for service init
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?._cameraService?.requestCameraPermission()
            }
            return
        }
        cameraService.requestCameraPermission()
    }

    private func handleAuthorizationStatusChange(_ status: AVAuthorizationStatus) {
        self.cameraAuthorizationStatus = status
        switch status {
        case .authorized:
            self.isCameraPermissionGranted = true
            self.workoutState = .ready
            self.feedbackMessage = "Ready for \(selectedExercise.displayName)."
            _cameraService?.startSession() // Start session if authorized
        case .notDetermined:
            self.isCameraPermissionGranted = false
            self.workoutState = .requestingPermission
            self.feedbackMessage = "Camera permission needed."
        case .denied, .restricted:
            self.isCameraPermissionGranted = false
            self.workoutState = .permissionDenied
            self.feedbackMessage = "Camera access denied. Enable in Settings."
            self.errorMessage = "Camera access is required for this feature."
        @unknown default:
            self.isCameraPermissionGranted = false
            self.workoutState = .error("Unknown camera permission status.")
            self.feedbackMessage = "Error with camera permissions."
        }
    }
    
    // MARK: - Grader Logic
    func updateGrader(for exerciseType: ExerciseType) {
        print("WorkoutViewModel: Updating grader for \(exerciseType.displayName)")
        self.exerciseGrader = Self.grader(for: exerciseType)
        self.exerciseGrader.resetState()
        updateUIFromGraderState()
        self.feedbackMessage = "Switched to \(exerciseType.displayName). \(exerciseGrader.currentPhaseDescription)"
    }

    static func grader(for exerciseType: ExerciseType) -> any ExerciseGraderProtocol {
        switch exerciseType {
        case .pushup: return PushupGrader()
        case .situp: return SitupGrader()
        case .pullup: return PullupGrader()
        default:
            print("WorkoutViewModel.grader: No specific grader for \(exerciseType.displayName). Using NoOpGrader.")
            return NoOpGrader()
        }
    }
    
    private func gradeFrame(body: DetectedBody) {
        let result = exerciseGrader.gradePose(body: body)
        handleGradingResult(result)
    }

    private func handleGradingResult(_ result: GradingResult) {
        switch result {
        case .repCompleted(let quality):
            feedbackMessage = "Rep! Quality: \(Int(quality * 100))%"
            repCompletedPublisher.send()
            // Sound/Haptics would go here
        case .inProgress(let phase):
            feedbackMessage = phase ?? exerciseGrader.currentPhaseDescription
        case .invalidPose(let reason):
            feedbackMessage = "Adjust: \(reason)"
        case .incorrectForm(let feedback):
            feedbackMessage = "Form: \(feedback)"
        case .noChange:
            feedbackMessage = exerciseGrader.currentPhaseDescription
        }
        updateUIFromGraderState()
    }

    private func updateUIFromGraderState() {
        self.repCount = exerciseGrader.repCount
        self.currentPhase = exerciseGrader.currentPhaseDescription
        self.problemJoints = exerciseGrader.problemJoints
        self.badJointNames = exerciseGrader.problemJoints
        self.formScore = exerciseGrader.formQualityAverage * 100
        if let issue = exerciseGrader.lastFormIssue, !issue.isEmpty {
            self.feedbackMessage = issue
        } else {
            self.feedbackMessage = exerciseGrader.currentPhaseDescription
        }
    }

    // MARK: - Workout Lifecycle
    func startWorkout() {
        guard isCameraPermissionGranted else {
            feedbackMessage = "Camera permission required."
            workoutState = .requestingPermission
            requestCameraAccess()
            return
        }
        guard workoutState == .ready || workoutState == .paused else { return }

        isWorkoutActive = true
        workoutState = .counting
        
        if workoutStartTime == nil || workoutState != .paused {
            accumulatedTime = 0
            workoutStartTime = Date()
        } else {
            // workoutStartTime should be the point we paused to calculate current segment
        }
        
        exerciseGrader.resetState()
        updateUIFromGraderState()
        feedbackMessage = "Workout Started: \(selectedExercise.displayName)"
        startTimer()
        _cameraService?.startSession()
    }

    func pauseWorkout() {
        guard workoutState == .counting else { return }
        isWorkoutActive = true
        workoutState = .paused
        feedbackMessage = "Workout Paused"
        pauseTimer()
    }

    func resumeWorkout() {
        guard workoutState == .paused else { return }
        isWorkoutActive = true
        workoutState = .counting
        feedbackMessage = "Resuming..."
        startTimer()
    }

    func stopWorkout() {
        stopWorkoutFlow(saveAttempt: true)
    }
    
    private func stopWorkoutFlow(saveAttempt: Bool) {
        guard isWorkoutActive else { return }

        let endTime = Date()
        pauseTimer()
        
        let finalRepCount = self.repCount
        let finalScore = exerciseGrader.calculateFinalScore()
        let finalFormQuality = exerciseGrader.formQualityAverage
        
        let durationSeconds = Int(accumulatedTime)

        isWorkoutActive = false
        workoutState = .finished
        feedbackMessage = "Workout Complete! Reps: \(finalRepCount)"
        elapsedTimeFormatted = formatTime(durationSeconds)

        print("WorkoutViewModel: Workout ended. Duration: \(durationSeconds)s, Reps: \(finalRepCount), Score: \(String(describing: finalScore)), Avg Form: \(finalFormQuality * 100)%")

        if saveAttempt {
            saveWorkoutResult(
                startTime: workoutStartTime ?? endTime.addingTimeInterval(-accumulatedTime),
                endTime: endTime,
                duration: durationSeconds,
                reps: finalRepCount,
                score: finalScore,
                formQuality: finalFormQuality
            )
        }
    }

    // MARK: - Timer Control
    private func startTimer() {
        guard !isTimerRunning else { return }
        
        let segmentStartDate = Date()
        isTimerRunning = true

        timerSubscription = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink { [weak self] firedDate in
                guard let self = self, self.isTimerRunning else { return }
                let currentSegmentTime = firedDate.timeIntervalSince(segmentStartDate)
                let totalElapsed = self.accumulatedTime + currentSegmentTime
                self.elapsedTimeFormatted = self.formatTime(Int(totalElapsed))
            }
    }

    private func pauseTimer() {
        guard isTimerRunning else { return }
        isTimerRunning = false
        if let segStart = workoutStartTime {
             accumulatedTime += Date().timeIntervalSince(segStart)
        }
        workoutStartTime = nil
        timerSubscription?.cancel()
    }

    private func stopTimer() {
        isTimerRunning = false
        timerSubscription?.cancel()
        timerSubscription = nil
        accumulatedTime = 0
        workoutStartTime = nil
        elapsedTimeFormatted = formatTime(0)
    }
    
    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Data Saving
    private func saveWorkoutResult(
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
            print("WorkoutViewModel: ModelContext not available.")
            errorMessage = "Failed to save: data context unavailable."
            return
        }

        let newResult = WorkoutResultSwiftData(
            exerciseType: selectedExercise.rawValue,
            startTime: startTime,
            endTime: endTime,
            durationSeconds: duration,
            repCount: reps,
            score: score,
            formQuality: formQuality * 100
        )
        context.insert(newResult)
        do {
            try context.save()
            print("WorkoutViewModel: Workout saved locally.")
        } catch {
            print("WorkoutViewModel: Failed to save workout locally: \(error.localizedDescription)")
            errorMessage = "Could not save workout: \(error.localizedDescription)"
        }
    }
}

// No-Operation Grader for exercises that don't use pose detection or for default state
final class NoOpGrader: ObservableObject, ExerciseGraderProtocol {
    static var targetFramesPerSecond: Double = 30.0
    static var requiredJointConfidence: Float = 0.1
    static var requiredStableFrames: Int = 1

    @Published var currentPhaseDescription: String = "Not applicable for this exercise."
    @Published var repCount: Int = 0
    @Published var formQualityAverage: Double = 0.0
    @Published var lastFormIssue: String? = nil
    @Published var problemJoints: Set<VNHumanBodyPoseObservation.JointName> = []

    func resetState() {
        currentPhaseDescription = "Not applicable for this exercise."
        repCount = 0
        formQualityAverage = 0.0
        lastFormIssue = nil
        problemJoints = []
    }
    func gradePose(body: DetectedBody) -> GradingResult { return .noChange }
    func calculateFinalScore() -> Double? { return nil }
}