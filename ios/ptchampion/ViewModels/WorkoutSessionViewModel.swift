import SwiftUI
import Combine
import AVFoundation
import SwiftData
import Vision // Only used for VNHumanBodyPoseObservation.JointName constants
import AudioToolbox

// Workout state enumeration to track the current state of a workout session
enum WorkoutSessionState: Equatable {
    case initializing
    case requestingPermission
    case permissionDenied
    case ready
    case counting
    case paused
    case finished
    case error(String)
    
    static func == (lhs: WorkoutSessionState, rhs: WorkoutSessionState) -> Bool {
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
class WorkoutSessionViewModel: ObservableObject {
    // MARK: - Published Properties for UI
    @Published var exerciseType: ExerciseType
    @Published var repCount: Int = 0
    @Published var feedbackMessage: String = "Prepare for exercise."
    @Published var isPaused: Bool = false
    @Published var isSoundEnabled: Bool = true
    @Published var workoutState: WorkoutSessionState = .initializing
    
    // For workout completion
    @Published var showWorkoutCompleteView: Bool = false
    @Published var completedWorkoutResult: WorkoutResultSwiftData?
    
    // Camera and pose detection related state
    @Published var cameraAuthorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var isCameraPermissionGranted: Bool = false
    @Published var detectedBody: DetectedBody? = nil
    @Published var problemJoints: Set<VNHumanBodyPoseObservation.JointName> = []
    
    // Error handling
    @Published var errorMessage: String? = nil
    @Published var showAlertForSaveError: Bool = false
    @Published var saveErrorMessage: String = ""
    
    // Add a flag to track if full body warning should be shown
    @Published var showFullBodyWarning: Bool = false
    
    // Add a flag to ignore late pose detection results
    @Published private var isWorkoutActive: Bool = false
    
    // MARK: - Services
    private var _cameraService: CameraServiceProtocol
    var cameraService: CameraServiceProtocol { _cameraService }
    
    private let poseDetectorService: PoseDetectorServiceProtocol
    private var exerciseGrader: any ExerciseGraderProtocol
    private let workoutTimer: WorkoutTimer
    private var currentWorkoutSessionID: UUID?
    
    // SwiftData
    var modelContext: ModelContext?
    
    // MARK: - Internal State
    private var cancellables = Set<AnyCancellable>()
    private var consecutiveFramesWithoutBody: Int = 0
    private let maxFramesWithoutBodyBeforeWarning = 15
    
    // Add a property to track if cleanup has already been performed
    private var hasPerformedCleanup: Bool = false
    
    // MARK: - Computed Properties
    var elapsedTimeFormatted: String {
        workoutTimer.formattedElapsedTime
    }
    
    // MARK: - Initialization
    init(
        exerciseType: ExerciseType,
        cameraService: CameraServiceProtocol = CameraService(),
        poseDetectorService: PoseDetectorServiceProtocol = PoseDetectorService(),
        exerciseGrader: (any ExerciseGraderProtocol)? = nil,
        workoutTimer: WorkoutTimer = WorkoutTimer(),
        modelContext: ModelContext? = nil
    ) {
        self.exerciseType = exerciseType
        self._cameraService = cameraService
        self.poseDetectorService = poseDetectorService
        self.workoutTimer = workoutTimer
        self.modelContext = modelContext
        
        if let providedGrader = exerciseGrader {
            self.exerciseGrader = providedGrader
        } else {
            self.exerciseGrader = Self.createGrader(for: exerciseType)
        }
        
        print("WorkoutSessionViewModel initialized for \(exerciseType.displayName) using \(type(of: self.exerciseGrader))")
        
        // Initialize UI with grader's state
        updateUIFromGraderState()
        feedbackMessage = "Ready for \(exerciseType.displayName)"
        
        // Setup subscribers and check camera permissions
        setupSubscribers()
        checkCameraPermission()
    }
    
    deinit {
        // Schedule cleanup on the main actor with weak self to avoid strong retention
        Task { @MainActor [weak self] in
            self?.cleanup()
            // Don't reference self directly here - could be deallocated
            print("WorkoutSessionViewModel deinitialized.")
        }
    }
    
    // MARK: - Setup and Cleanup
    private func setupSubscribers() {
        // Camera authorization status
        cameraService.authorizationStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handleAuthorizationStatusChange(status)
            }
            .store(in: &cancellables)
        
        // Camera frames
        cameraService.framePublisher
            .compactMap { $0 }
            .sink { [weak self] frame in
                guard let self = self,
                      self.isWorkoutActive, // Only process if workout is active
                      !self.isPaused,
                      !isErrorState(self.workoutState),
                      self.workoutState != .finished else { return }
                
                // Process frames for pose detection in both ready and counting states
                // This allows the skeleton to appear as soon as the camera starts
                if self.workoutState == .ready || self.workoutState == .counting {
                    self.poseDetectorService.processFrame(frame)
                }
            }
            .store(in: &cancellables)
        
        // Pose detection
        poseDetectorService.detectedBodyPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] body in
                guard let self = self, 
                      self.isWorkoutActive else { return } // Only process if workout is active
                      
                self.detectedBody = body
                
                if let body = body {
                    if self.workoutState == .counting && !self.isPaused {
                        self.consecutiveFramesWithoutBody = 0
                        let result = self.exerciseGrader.gradePose(body: body)
                        self.handleGradingResult(result)
                    }
                } else {
                    self.handleBodyLost()
                }
            }
            .store(in: &cancellables)
        
        // Error handling
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
    
    // Make cleanup public instead of private to allow external calls
    public func cleanup() {
        // Avoid performing cleanup multiple times unnecessarily
        if hasPerformedCleanup {
            print("Cleanup already performed for \(exerciseType.displayName) workout - skipping")
            return
        }
        
        print("Performing cleanup for \(exerciseType.displayName) workout")
        hasPerformedCleanup = true
        
        // Mark workout as inactive to prevent late callbacks from processing
        isWorkoutActive = false
        
        // Cancel all publishers - this is safe to call multiple times
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        // Stop timer if running - safe to call if already stopped
        workoutTimer.stop()
        
        // Stop camera session - CameraService handles this safely if already stopped
        cameraService.stopSession()
        
        // Ensure we mark the workout as finished if not already
        if workoutState != .finished && workoutState != .error("Camera error occurred") {
            workoutState = .finished
        }
    }
    
    // Public method for external cleanup
    func cleanupResources() {
        // Just call the main cleanup method
        cleanup()
    }
    
    // MARK: - Camera Permission Handling
    func requestCameraPermission() {
        cameraService.requestCameraPermission()
    }
    
    // Public method to check camera permission
    func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        handleAuthorizationStatusChange(status)
        
        // Start camera session if authorized, but don't start the workout
        if status == .authorized {
            cameraService.startSession()
        }
    }
    
    private func handleAuthorizationStatusChange(_ status: AVAuthorizationStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.cameraAuthorizationStatus = status
            
            switch status {
            case .authorized:
                self.isCameraPermissionGranted = true
                self.workoutState = .ready
                self.feedbackMessage = "Ready for \(self.exerciseType.displayName)"
                self.cameraService.startSession()
                
            case .notDetermined:
                self.isCameraPermissionGranted = false
                self.workoutState = .requestingPermission
                self.feedbackMessage = "Camera permission needed"
                
            case .denied, .restricted:
                self.isCameraPermissionGranted = false
                self.workoutState = .permissionDenied
                self.feedbackMessage = "Camera access denied. Enable in Settings."
                
            @unknown default:
                self.isCameraPermissionGranted = false
                self.workoutState = .error("Unknown camera permission status")
            }
        }
    }
    
    // MARK: - Workout Session Controls
    func startWorkout() {
        guard isCameraPermissionGranted else {
            workoutState = .requestingPermission
            return
        }
        
        // Mark workout as active
        isWorkoutActive = true
        
        // Only create a new session ID if we don't already have one
        // This prevents issues if startWorkout is called multiple times
        if currentWorkoutSessionID == nil {
            currentWorkoutSessionID = UUID()
        }
        
        exerciseGrader.resetState()
        updateUIFromGraderState()
        
        workoutState = .counting
        isPaused = false
        
        workoutTimer.reset()
        workoutTimer.start()
        
        cameraService.startSession()
    }
    
    func togglePause() {
        isPaused.toggle()
        
        if isPaused {
            workoutTimer.pause()
            feedbackMessage = "Paused"
        } else {
            workoutTimer.resume()
            updateUIFromGraderState() // Reset feedback to current state
        }
    }
    
    func toggleSound() {
        isSoundEnabled.toggle()
    }
    
    func switchCamera() {
        cameraService.switchCamera()
    }
    
    func finishWorkout() {
        print("Finishing workout for \(exerciseType.displayName)...")
        
        // Always stop timer and set paused
        isPaused = true
        workoutTimer.stop()
        
        // Stop camera session immediately to prevent frames from continuing to process
        cameraService.stopSession()
        
        // Cancel all subscriptions to prevent callbacks during transition
        cancellables.forEach { $0.cancel() }
        
        // If no workout session ID exists, we can't save a result
        // This shouldn't happen with our UI flow, but adding extra protection
        guard let workoutID = currentWorkoutSessionID else {
            print("Error: Workout session ID is nil. Cannot finalize workout.")
            saveErrorMessage = "Workout session ID was lost. Cannot save workout."
            showAlertForSaveError = true
            workoutState = .finished // Still mark as finished to ensure cleanup
            return
        }
        
        let finalScore = exerciseGrader.calculateFinalScore()
        let workoutEndTime = Date()
        let actualDuration = workoutTimer.elapsedTime
        let startTime = workoutTimer.workoutStartTime ?? workoutEndTime
        
        let newResult = WorkoutResultSwiftData(
            exerciseType: self.exerciseType.rawValue,
            startTime: startTime,
            endTime: workoutEndTime,
            durationSeconds: actualDuration,
            repCount: self.repCount,
            score: finalScore,
            formQuality: exerciseGrader.formQualityAverage,
            distanceMeters: nil,
            isPublic: false
        )
        
        newResult.id = workoutID
        
        if let modelContext = modelContext {
            modelContext.insert(newResult)
            do {
                try modelContext.save()
                completedWorkoutResult = newResult
                showWorkoutCompleteView = true
                print("Workout saved successfully with ID: \(workoutID.uuidString)")
            } catch {
                print("Failed to save workout: \(error.localizedDescription)")
                saveErrorMessage = "Could not save your workout. Error: \(error.localizedDescription)"
                showAlertForSaveError = true
            }
        } else {
            saveErrorMessage = "Could not save workout: No database context available"
            showAlertForSaveError = true
            print("No model context available to save workout")
        }
        
        workoutState = .finished
        print("Workout state set to finished")
    }
    
    // MARK: - Grading Result Handling
    private func handleGradingResult(_ result: GradingResult) {
        switch result {
        case .repCompleted(let formQuality):
            updateUIFromGraderState()
            feedbackMessage = "Rep Complete! Quality: \(Int(formQuality * 100))%"
            showFullBodyWarning = false
            
            if isSoundEnabled {
                AudioServicesPlaySystemSound(1104) // System beep sound
                let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                impactGenerator.prepare()
                impactGenerator.impactOccurred()
            }
            
            saveRepData(formQuality: formQuality)
            
        case .inProgress(let phase):
            feedbackMessage = phase ?? exerciseGrader.currentPhaseDescription
            showFullBodyWarning = false
            
        case .invalidPose(let reason):
            feedbackMessage = reason
            showFullBodyWarning = true
            
        case .incorrectForm(let feedback):
            feedbackMessage = feedback
            showFullBodyWarning = false
            
        case .noChange:
            feedbackMessage = exerciseGrader.currentPhaseDescription
            showFullBodyWarning = false
        }
        
        // Always update rep count from grader
        self.repCount = exerciseGrader.repCount
    }
    
    private func handleBodyLost() {
        consecutiveFramesWithoutBody += 1
        if consecutiveFramesWithoutBody > maxFramesWithoutBodyBeforeWarning && workoutState == .counting {
            showFullBodyWarning = true
            feedbackMessage = "Your full body is not in view of the camera. No reps will be counted."
        }
    }
    
    private func updateUIFromGraderState() {
        repCount = exerciseGrader.repCount
        feedbackMessage = exerciseGrader.currentPhaseDescription
        problemJoints = exerciseGrader.problemJoints
    }
    
    private func saveRepData(formQuality: Double) {
        guard let workoutID = currentWorkoutSessionID, let modelContext = modelContext else {
            print("Error: Cannot save rep data - missing workout ID or context")
            return
        }
        
        let repData = WorkoutDataPoint(
            timestamp: Date(),
            exerciseName: exerciseType.displayName,
            repNumber: self.repCount,
            formQuality: formQuality,
            phase: exerciseGrader.currentPhaseDescription,
            workoutID: workoutID
        )
        
        modelContext.insert(repData)
    }
    
    // MARK: - Error Handling
    private func handleServiceError(_ error: Error, serviceName: String) {
        print("\(serviceName) Error: \(error.localizedDescription)")
        errorMessage = "\(serviceName) error: \(error.localizedDescription)"
        
        if serviceName == "Camera" {
            workoutState = .error("Camera error occurred")
            // Stop the session without saving if camera fails
            cleanup()
        }
    }
    
    // MARK: - Helper Methods
    static func createGrader(for exerciseType: ExerciseType) -> any ExerciseGraderProtocol {
        switch exerciseType {
        case .pushup:
            return PushupGrader()
        case .situp:
            return SitupGrader()
        case .pullup:
            return PullupGrader()
        default:
            print("Warning: No specific grader for \(exerciseType.displayName). Using placeholder grader.")
            return WorkoutSessionPlaceholderGrader()
        }
    }
    
    // Helper method to check if in error state
    private func isErrorState(_ state: WorkoutSessionState) -> Bool {
        if case .error(_) = state {
            return true
        }
        return false
    }
}

// MARK: - PlaceholderGrader
internal final class WorkoutSessionPlaceholderGrader: ObservableObject, ExerciseGraderProtocol {
    @Published var currentPhaseDescription: String = "Not Implemented"
    @Published var repCount: Int = 0
    @Published var formQualityAverage: Double = 0.0
    @Published var lastFormIssue: String? = nil
    @Published var problemJoints: Set<VNHumanBodyPoseObservation.JointName> = []
    
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