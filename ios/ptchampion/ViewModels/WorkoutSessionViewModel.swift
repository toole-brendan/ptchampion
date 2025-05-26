// ios/ptchampion/ViewModels/WorkoutSessionViewModel.swift

import SwiftUI
import Combine
import AVFoundation
import SwiftData
import Vision // Only used for VNHumanBodyPoseObservation.JointName constants - no Vision detection
import AudioToolbox
#if canImport(UIKit)
import UIKit
#endif

// Workout state enumeration to track the current state of a workout session
enum WorkoutSessionState: Equatable {
    case initializing
    case requestingPermission
    case permissionDenied
    case ready
    case positionValidation  // New state for position checking
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
             (.positionValidation, .positionValidation),
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
    
    // Simple rep feedback
    @Published var showRepFeedback: Bool = false
    @Published var isRepSuccess: Bool = false
    
    // Add published property for elapsed time to ensure UI updates
    @Published var elapsedTimeFormatted: String = "00:00"
    
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
    
    // Track device orientation for pose detection adjustments
    @Published var currentOrientation: UIInterfaceOrientation = .portrait
    
    // MARK: - Calibration Properties
    @Published var showCalibrationView: Bool = false
    @Published var calibrationData: CalibrationData?
    @Published var calibrationQuality: CalibrationQuality = .invalid
    @Published var hasCheckedCalibration: Bool = false
    
    // MARK: - Real-time Feedback
    let realTimeFeedbackManager: RealTimeFeedbackManager
    let calibrationRepository: CalibrationRepository?
    
    // MARK: - Feedback Message Persistence
    // To prevent form feedback from flickering away too quickly
    private var lastFormFeedback: String = ""
    private var lastFormFeedbackTimestamp: Date = Date.distantPast
    private let formFeedbackDisplayDuration: TimeInterval = 2.0 // 2 seconds
    
    // MARK: - Services
    private var _cameraService: CameraServiceProtocol
    var cameraService: CameraServiceProtocol { _cameraService }
    
    private let poseDetectorService: PoseDetectorServiceProtocol
    internal var exerciseGrader: any ExerciseGraderProtocol
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
        
        // Initialize calibration repository
        self.calibrationRepository = CalibrationRepository()
        
        // Initialize real-time feedback manager with APFTRepValidator
        let apftValidator = APFTRepValidator()
        self.realTimeFeedbackManager = RealTimeFeedbackManager(
            poseDetectorService: poseDetectorService,
            apftValidator: apftValidator
        )
        
        if let providedGrader = exerciseGrader {
            self.exerciseGrader = providedGrader
        } else {
            self.exerciseGrader = Self.createGrader(for: exerciseType)
        }
        
        print("WorkoutSessionViewModel initialized for \(exerciseType.displayName) using \(type(of: self.exerciseGrader))")
        
        // Initialize UI with grader's state
        updateUIFromGraderState()
        feedbackMessage = "Get ready to begin"
        
        // Setup subscribers and check camera permissions
        setupSubscribers()
        checkCameraPermission()
        
        // Initialize current orientation
        currentOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .portrait
        
        // Don't check calibration in init - wait until the view is ready
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
        // Timer updates - observe the timer's formatted elapsed time
        workoutTimer.$formattedElapsedTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] formattedTime in
                self?.elapsedTimeFormatted = formattedTime
            }
            .store(in: &cancellables)
        
        // Camera authorization status
        cameraService.authorizationStatusPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                print("DEBUG: [WorkoutSessionViewModel] Camera auth status changed: \(status.rawValue)")
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
            .receive(on: RunLoop.main)
            .sink { [weak self] body in
                guard let self = self, 
                      self.isWorkoutActive else { return } // Only process if workout is active
                      
                print("DEBUG: [WorkoutSessionViewModel] Received body detection update: \(body != nil)")
                
                // Always update body in the next run loop to avoid view update cycles
                DispatchQueue.main.async {
                    self.detectedBody = body
                    
                    if let body = body {
                        if self.workoutState == .counting && !self.isPaused {
                            self.consecutiveFramesWithoutBody = 0
                            let result = self.exerciseGrader.gradePose(body: body)
                            // Already in main queue context
                            self.handleGradingResult(result)
                        }
                    } else {
                        self.handleBodyLost()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Error handling
        cameraService.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                print("DEBUG: [WorkoutSessionViewModel] Camera service error: \(error.localizedDescription)")
                self?.handleServiceError(error, serviceName: "Camera")
            }
            .store(in: &cancellables)
        
        poseDetectorService.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                print("DEBUG: [WorkoutSessionViewModel] Pose detector error: \(error.localizedDescription)")
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
        
        // Mark workout as inactive to prevent late callbacks from processing
        isWorkoutActive = false
        
        // Cancel all publishers first
        for cancellable in cancellables {
            cancellable.cancel()
        }
        cancellables.removeAll()
        
        // Stop timer if running - safe to call if already stopped
        workoutTimer.stop()
        
        // Stop camera session - ensure this happens on the main thread
        // to avoid potential threading issues
        DispatchQueue.main.async {
            self.cameraService.stopSession()
            
            // Mark cleanup as complete after a short delay to ensure all resources are released
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.hasPerformedCleanup = true
                
                // Ensure we mark the workout as finished if not already
                if self.workoutState != .finished && self.workoutState != .error("Camera error occurred") {
                    self.workoutState = .finished
                }
            }
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
        print("DEBUG: [WorkoutSessionViewModel] Checking camera permission")
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        print("DEBUG: [WorkoutSessionViewModel] Current camera permission status: \(status.rawValue)")
        handleAuthorizationStatusChange(status)
    }
    
    private func handleAuthorizationStatusChange(_ status: AVAuthorizationStatus) {
        print("DEBUG: [WorkoutSessionViewModel] Handling auth status change: \(status.rawValue) on thread: \(Thread.isMainThread ? "main" : "background")")
        
        // Ensure we're updating state on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                print("DEBUG: [WorkoutSessionViewModel] Self deallocated during auth handling")
                return
            }
            
            print("DEBUG: [WorkoutSessionViewModel] Setting cameraAuthorizationStatus to \(status.rawValue)")
            self.cameraAuthorizationStatus = status
            
            switch status {
            case .authorized:
                print("DEBUG: [WorkoutSessionViewModel] Camera authorized, updating state")
                self.isCameraPermissionGranted = true
                self.workoutState = .ready
                self.feedbackMessage = "Prepare to begin"
                
                // Start camera in next run loop to avoid state update during view render
                DispatchQueue.main.async {
                    print("DEBUG: [WorkoutSessionViewModel] Starting camera session (authorized)")
                    self.cameraService.startSession()
                }
                
            case .notDetermined:
                print("DEBUG: [WorkoutSessionViewModel] Camera permission not determined")
                self.isCameraPermissionGranted = false
                self.workoutState = .requestingPermission
                self.feedbackMessage = "Camera permission needed"
                
            case .denied, .restricted:
                print("DEBUG: [WorkoutSessionViewModel] Camera permission denied or restricted")
                self.isCameraPermissionGranted = false
                self.workoutState = .permissionDenied
                self.feedbackMessage = "Camera access denied. Enable in Settings."
                
            @unknown default:
                print("DEBUG: [WorkoutSessionViewModel] Unknown camera permission status")
                self.isCameraPermissionGranted = false
                self.workoutState = .error("Unknown camera permission status")
            }
        }
    }
    
    // MARK: - Workout Session Controls
    func startWorkout() {
        print("DEBUG: [WorkoutSessionViewModel] startWorkout() called, permission granted: \(isCameraPermissionGranted)")
        
        guard isCameraPermissionGranted else {
            print("DEBUG: [WorkoutSessionViewModel] Cannot start workout - missing camera permission")
            DispatchQueue.main.async {
                self.workoutState = .requestingPermission
            }
            return
        }
        
        // Updating all state in a single async block to batch changes
        DispatchQueue.main.async {
            print("DEBUG: [WorkoutSessionViewModel] Starting workout (async)")
            
            // Mark workout as active
            self.isWorkoutActive = true
            print("DEBUG: [WorkoutSessionViewModel] Set isWorkoutActive = true")
            
            // Only create a new session ID if we don't already have one
            if self.currentWorkoutSessionID == nil {
                print("DEBUG: [WorkoutSessionViewModel] Creating new workout session ID")
                self.currentWorkoutSessionID = UUID()
            }
            
            self.exerciseGrader.resetState()
            self.updateUIFromGraderState()
            
            // Start real-time feedback with calibration data
            print("DEBUG: [WorkoutSessionViewModel] Starting real-time feedback with calibration: \(self.calibrationData != nil)")
            self.realTimeFeedbackManager.startFeedback(for: self.exerciseType, with: self.calibrationData)
            
            // Force workout state to counting and ensure isPaused is false
            self.workoutState = .counting
            self.isPaused = false
            self.feedbackMessage = "Workout active"
            print("DEBUG: [WorkoutSessionViewModel] Set workoutState = .counting, isPaused = false")
            
            // Always start the timer fresh
            print("DEBUG: [WorkoutSessionViewModel] About to reset and start timer")
            self.workoutTimer.reset()
            self.workoutTimer.start()
            print("DEBUG: [WorkoutSessionViewModel] Timer started, isRunning: \(self.workoutTimer.isRunning)")
            
            // Start camera in next run loop
            DispatchQueue.main.async {
                print("DEBUG: [WorkoutSessionViewModel] Starting camera session for workout")
                self.cameraService.startSession()
            }
        }
    }
    
    func togglePause() {
        isPaused.toggle()
        
        if isPaused {
            workoutTimer.pause()
            feedbackMessage = "Workout paused"
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
    
    // MARK: - Orientation Handling
    func handleOrientationChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let newOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .portrait
            if self.currentOrientation != newOrientation {
                print("DEBUG: [WorkoutSessionViewModel] Orientation changed from \(self.currentOrientation.rawValue) to \(newOrientation.rawValue)")
                self.currentOrientation = newOrientation
                
                // Update camera service orientation
                self.cameraService.updateOutputOrientation()
                
                // Recalibrate pose detection if needed
                self.recalibratePoseDetection()
            }
        }
    }

    private func recalibratePoseDetection() {
        // Reset any orientation-dependent calibration
        // This might include resetting reference poses or adjusting detection thresholds
        print("DEBUG: [WorkoutSessionViewModel] Recalibrating pose detection for new orientation")
        
        // Reset the grader state to account for new orientation
        if workoutState == .counting || workoutState == .ready {
            exerciseGrader.resetState()
            updateUIFromGraderState()
        }
    }
    
    func finishWorkout() {
        print("Finishing workout for \(exerciseType.displayName)...")
        
        // Always stop timer and set paused
        isPaused = true
        workoutTimer.stop()
        
        // Stop real-time feedback
        realTimeFeedbackManager.stopFeedback()
        
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
        // Create local copies of data to update
        var newFeedbackMessage: String
        var newShowFullBodyWarning: Bool
        var newRepCount: Int = 0
        
        // Extract the data based on the result without modifying state yet
        switch result {
        case .repCompleted(let formQuality):
            updateUIFromGraderState()
            newFeedbackMessage = "Good rep!"
            newShowFullBodyWarning = false
            
            // Show success feedback
            showRepFeedback = true
            isRepSuccess = true
            
            if isSoundEnabled {
                AudioServicesPlaySystemSound(1104) // System beep sound
            }
            // Haptic feedback completely removed
            
            saveRepData(formQuality: formQuality)
            
            // Reset form feedback state since we've completed a rep
            lastFormFeedback = ""
            lastFormFeedbackTimestamp = Date.distantPast
            
            // Hide feedback after 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.showRepFeedback = false
            }
            
        case .inProgress(let phase):
            // Check if we should still display the previous form feedback
            if !lastFormFeedback.isEmpty && Date().timeIntervalSince(lastFormFeedbackTimestamp) < formFeedbackDisplayDuration {
                // Continue showing the form feedback
                newFeedbackMessage = lastFormFeedback
            } else {
                newFeedbackMessage = phase ?? exerciseGrader.currentPhaseDescription
            }
            newShowFullBodyWarning = false
            
        case .invalidPose(let reason):
            newFeedbackMessage = reason
            newShowFullBodyWarning = true
            
        case .incorrectForm(let feedback):
            newFeedbackMessage = feedback
            newShowFullBodyWarning = false
            
            // Show failure feedback (red X)
            showRepFeedback = true
            isRepSuccess = false
            
            // Store this form feedback to persist it
            lastFormFeedback = feedback
            lastFormFeedbackTimestamp = Date()
            
            // Hide feedback after 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.showRepFeedback = false
            }
            
        case .noChange:
            // Check if we should still display the previous form feedback
            if !lastFormFeedback.isEmpty && Date().timeIntervalSince(lastFormFeedbackTimestamp) < formFeedbackDisplayDuration {
                // Continue showing the form feedback
                newFeedbackMessage = lastFormFeedback
            } else {
                newFeedbackMessage = exerciseGrader.currentPhaseDescription
            }
            newShowFullBodyWarning = false
        }
        
        // Get the rep count from the grader
        newRepCount = exerciseGrader.repCount
        
        // Update problem joints from the grader
        let newProblemJoints = exerciseGrader.problemJoints
        
        // Update the published properties only once, which allows SwiftUI to batch the changes
        self.feedbackMessage = newFeedbackMessage
        self.showFullBodyWarning = newShowFullBodyWarning
        self.repCount = newRepCount
        self.problemJoints = newProblemJoints
    }
    
    private func handleBodyLost() {
        consecutiveFramesWithoutBody += 1
        if consecutiveFramesWithoutBody > maxFramesWithoutBodyBeforeWarning && workoutState == .counting {
            // Create local variables for state updates
            let newFeedbackMessage = "Warning: Please position your entire body in the frame."
            
            // Apply state changes in a batch
            self.feedbackMessage = newFeedbackMessage
            self.showFullBodyWarning = true
            
            // Reset form feedback state
            lastFormFeedback = ""
            lastFormFeedbackTimestamp = Date.distantPast
        }
    }
    
    private func updateUIFromGraderState() {
        // Create local variables to batch the changes
        let newRepCount = exerciseGrader.repCount
        let newFeedbackMessage = exerciseGrader.currentPhaseDescription
        let newProblemJoints = exerciseGrader.problemJoints
        
        // Apply all changes at once
        self.repCount = newRepCount
        self.feedbackMessage = newFeedbackMessage
        self.problemJoints = newProblemJoints
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
            return EnhancedPushupGrader()
        case .situp:
            return EnhancedSitupGrader()
        case .pullup:
            return EnhancedPullupGrader()
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
