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

// Enhanced workout state enumeration following the progressive enhancement model
enum WorkoutSessionState: Equatable {
    case initializing
    case requestingPermission
    case permissionDenied
    case ready
    case waitingForPosition    // New: User pressed GO, waiting for correct position
    case positionDetected      // New: Correct position detected, ready to start
    case countdown             // New: 3-2-1 countdown before exercise begins
    case counting              // Exercise in progress
    case paused
    case finished
    case error(String)
    
    static func == (lhs: WorkoutSessionState, rhs: WorkoutSessionState) -> Bool {
        switch (lhs, rhs) {
        case (.initializing, .initializing),
             (.requestingPermission, .requestingPermission),
             (.permissionDenied, .permissionDenied),
             (.ready, .ready),
             (.waitingForPosition, .waitingForPosition),
             (.positionDetected, .positionDetected),
             (.countdown, .countdown),
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

// MARK: - Position Quality for Better UX
enum PositionQuality: Equatable {
    case notDetected
    case poor(reason: String)      // Red - major issues
    case fair(adjustment: String)  // Yellow - minor adjustments needed  
    case good                      // Green - ready to start
    case perfect                   // Green with checkmark
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
    
    // Add these properties to prevent race conditions
    private(set) var isRecalibrating = false
    private var orientationChangeDebouncer: Timer?
    private var lastOrientation: UIInterfaceOrientation = .portrait
    private var lastProcessedOrientation: UIInterfaceOrientation?
    
    // MARK: - Enhanced Position Detection Properties
    @Published var positionQuality: PositionQuality = .notDetected
    @Published var simpleVisualFeedback: String = "GET READY"
    @Published var backgroundColor: Color = .gray
    
    // MARK: - Auto Position Detection
    // TODO: Re-enable auto position detection once module compilation issues are resolved
    // private let autoPositionDetector = AutoPositionDetector()
    @Published var positionHoldProgress: Float = 0.0
    @Published var countdownValue: Int? = nil
    
    // Additional properties for position detection feedback
    @Published var currentInstruction: String = ""
    @Published var positioningConfidence: Double = 0.0
    @Published var missingRequirements: [String] = []
    
    // Computed property to expose autoPositionDetector for UI
    // TODO: Re-enable once AutoPositionDetector is available
    // var autoPositionDetectorForUI: AutoPositionDetector {
    //     return autoPositionDetector
    // }
    
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
    
    // Add properties for tracking position hold time
    @Published var isInCorrectStartingPosition: Bool = false
    private var correctPositionStartTime: Date?
    private let requiredPositionHoldDuration: TimeInterval = 0.5 // Reduced from 1.0 to 0.5 seconds for better UX
    
    // MARK: - Audio Feedback
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var positionLostTime: Date?
    private let positionGracePeriod: TimeInterval = 1.0 // 1 second grace period
    
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
        
        // Auto position detector is initialized as a property
        
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
        lastOrientation = currentOrientation
        lastProcessedOrientation = currentOrientation
        
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
                
                // Process frames for pose detection in ready, waitingForPosition, and counting states
                // This allows the skeleton to appear immediately when waiting for position
                if self.workoutState == .ready || 
                   self.workoutState == .waitingForPosition || 
                   self.workoutState == .counting {
                    self.poseDetectorService.processFrame(frame)
                }
            }
            .store(in: &cancellables)
        
        // Pose detection with auto position detection
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
                        // Handle auto position detection for new states
                        if self.workoutState == .waitingForPosition {
                            self.handleAutoPositionDetection(body: body)
                        } else if self.workoutState == .counting && !self.isPaused {
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
        
        // Auto position detector state changes - Fixed with proper type annotations
        // autoPositionDetector.$currentDetection
        //     .receive(on: DispatchQueue.main)
        //     .sink { [weak self] (detection: PositionDetectionResult?) in
        //         guard let self = self, let detection = detection else { return }
        //         self.handlePositionDetection(detection)
        //     }
        //     .store(in: &cancellables)
        
        // autoPositionDetector.$positionQuality
        //     .receive(on: DispatchQueue.main)
        //     .sink { [weak self] (quality: Float) in
        //         self?.positionHoldProgress = self?.autoPositionDetector.getPositionHoldProgress() ?? 0.0
        //     }
        //     .store(in: &cancellables)
        
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
        
        // Stop automatic position detection
        // stopAutomaticPositionDetection()
        
        // Cancel orientation debouncer
        orientationChangeDebouncer?.invalidate()
        orientationChangeDebouncer = nil
        
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
    
    /// New "Just Press GO" method - starts position detection flow
    func startPositionDetection() {
        print("DEBUG: [WorkoutSessionViewModel] startPositionDetection() called - implementing 'Just Press GO' flow")
        
        guard isCameraPermissionGranted else {
            print("DEBUG: [WorkoutSessionViewModel] Cannot start position detection - missing camera permission")
            DispatchQueue.main.async {
                self.workoutState = .requestingPermission
            }
            return
        }
        
        DispatchQueue.main.async {
            print("DEBUG: [WorkoutSessionViewModel] Starting position detection flow")
            
            // Mark workout as active for frame processing
            self.isWorkoutActive = true
            
            // Reset auto position detector
            // self.autoPositionDetector.reset()
            
            // Start automatic position detection
            // self.startAutomaticPositionDetection()
            
            // Transition to waiting for position state
            self.workoutState = .waitingForPosition
            self.feedbackMessage = "Get into starting position"
            self.currentInstruction = "Get into starting position"
            
            // Start camera session
            DispatchQueue.main.async {
                print("DEBUG: [WorkoutSessionViewModel] Starting camera session for position detection")
                self.cameraService.startSession()
            }
        }
    }
    
    /// Legacy method - now calls the new position detection flow
    func startWorkout() {
        print("DEBUG: [WorkoutSessionViewModel] startWorkout() called - redirecting to position detection flow")
        startPositionDetection()
    }
    
    /// Called when correct position is detected and held
    func handlePositionDetected() {
        print("DEBUG: [WorkoutSessionViewModel] Position detected! Starting countdown")
        
        DispatchQueue.main.async {
            self.workoutState = .positionDetected
            self.feedbackMessage = "Perfect! Starting in..."
            
            // Voice announcement
            self.speakText("Get ready")
            
            // Short haptic feedback
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            #endif
            
            // Start 3-second countdown
            self.startCountdown()
        }
    }
    
    /// Starts the 3-2-1 countdown before exercise begins
    private func startCountdown() {
        print("DEBUG: [WorkoutSessionViewModel] Starting countdown sequence")
        
        var countdown = 3
        self.countdownValue = countdown
        self.workoutState = .countdown
        
        // Announce first number immediately
        self.speakText("\(countdown)")
        
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            countdown -= 1
            
            if countdown > 0 {
                self.countdownValue = countdown
                self.feedbackMessage = "Starting in \(countdown)..."
                self.speakText("\(countdown)")
            } else {
                timer.invalidate()
                self.countdownValue = nil
                self.speakText("Begin")
                self.beginExercise()
            }
        }
    }
    
    /// Actually begins the exercise after countdown
    private func beginExercise() {
        print("DEBUG: [WorkoutSessionViewModel] Beginning exercise after countdown")
        
        DispatchQueue.main.async {
            // Only create a new session ID if we don't already have one
            if self.currentWorkoutSessionID == nil {
                print("DEBUG: [WorkoutSessionViewModel] Creating new workout session ID")
                self.currentWorkoutSessionID = UUID()
            }
            
            // Reset the grader since we used it for position detection
            self.exerciseGrader.resetState()
            self.updateUIFromGraderState()
            
            // Reset position tracking
            self.correctPositionStartTime = nil
            self.positionHoldProgress = 0.0
            self.isInCorrectStartingPosition = false
            
            // Start real-time feedback with calibration data
            print("DEBUG: [WorkoutSessionViewModel] Starting real-time feedback with calibration: \(self.calibrationData != nil)")
            self.realTimeFeedbackManager.startFeedback(for: self.exerciseType, with: self.calibrationData)
            
            // Transition to counting state
            self.workoutState = .counting
            self.isPaused = false
            self.feedbackMessage = "Workout active"
            print("DEBUG: [WorkoutSessionViewModel] Set workoutState = .counting, isPaused = false")
            
            // Start the timer
            print("DEBUG: [WorkoutSessionViewModel] About to reset and start timer")
            self.workoutTimer.reset()
            self.workoutTimer.start()
            print("DEBUG: [WorkoutSessionViewModel] Timer started, isRunning: \(self.workoutTimer.isRunning)")
        }
    }
    
    /// Handles auto position detection during waitingForPosition state
    private func handleAutoPositionDetection(body: DetectedBody) {
        guard workoutState == .waitingForPosition else { return }
        
        // Update position quality and visual feedback
        updatePositionQuality(for: body)
        
        // Check if user is roughly in position (much more lenient than before)
        let isRoughlyInPosition = checkBasicPushupPosition(body)
        
        if isRoughlyInPosition {
            // Start timing if not already
            if correctPositionStartTime == nil {
                correctPositionStartTime = Date()
                provideAudioFeedback(for: positionQuality)
            }
            
            // Calculate hold progress
            let timeHeld = Date().timeIntervalSince(correctPositionStartTime ?? Date())
            positionHoldProgress = Float(min(timeHeld / requiredPositionHoldDuration, 1.0))
            
            // Start workout if held long enough
            if timeHeld >= requiredPositionHoldDuration {
                handlePositionDetected()
                correctPositionStartTime = nil
                positionHoldProgress = 0.0
                positionLostTime = nil
            }
        } else {
            // Handle position loss with grace period
            handlePositionLoss()
        }
        
        // Always update the grader to keep form feedback current
        let _ = exerciseGrader.gradePose(body: body)
    }
    
    /// Updates position quality based on body detection
    private func updatePositionQuality(for body: DetectedBody) {
        // Level 1: Basic body detection
        guard detectBasicHumanForm(body) else {
            positionQuality = .notDetected
            simpleVisualFeedback = "STEP INTO VIEW"
            backgroundColor = .gray
            feedbackMessage = "Step into camera view"
            return
        }
        
        // Level 2: Check if roughly in push-up position
        let inPosition = checkBasicPushupPosition(body)
        let adjustment = getPositionAdjustment(body)
        
        if !inPosition {
            positionQuality = .poor(reason: adjustment)
            simpleVisualFeedback = "GET DOWN"
            backgroundColor = .red
            feedbackMessage = adjustment
        } else {
            // Level 3: In position, check quality
            let formIssues = checkBasicFormIssues(body)
            if formIssues.isEmpty {
                positionQuality = .good
                simpleVisualFeedback = "HOLD STEADY"
                backgroundColor = .green
                feedbackMessage = "Hold steady..."
            } else {
                positionQuality = .fair(adjustment: formIssues.first ?? "Adjust position")
                simpleVisualFeedback = "ALMOST THERE"
                backgroundColor = .yellow
                feedbackMessage = formIssues.first ?? "Almost there"
            }
        }
    }
    
    /// Checks if basic human form is detected with required joints
    private func detectBasicHumanForm(_ body: DetectedBody) -> Bool {
        // Just need to see key joints
        let requiredJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftWrist, .rightWrist,
            .leftShoulder, .rightShoulder,
            .leftHip, .rightHip
        ]
        
        for joint in requiredJoints {
            guard let _ = body.point(joint) else {
                return false
            }
        }
        return true
    }
    
    /// Very lenient check for basic push-up position
    private func checkBasicPushupPosition(_ body: DetectedBody) -> Bool {
        guard let leftWrist = body.point(.leftWrist),
              let rightWrist = body.point(.rightWrist),
              let leftShoulder = body.point(.leftShoulder),
              let rightShoulder = body.point(.rightShoulder),
              let leftHip = body.point(.leftHip),
              let rightHip = body.point(.rightHip) else {
            return false
        }
        
        // Calculate average positions
        let avgWristY = (leftWrist.location.y + rightWrist.location.y) / 2
        let avgShoulderY = (leftShoulder.location.y + rightShoulder.location.y) / 2
        let avgHipY = (leftHip.location.y + rightHip.location.y) / 2
        
        // Very lenient checks:
        // 1. Wrists should be lower than shoulders (hands on ground)
        // Note: In normalized coordinates, lower Y = higher on screen
        let handsOnGround = avgWristY < avgShoulderY - 0.05
        
        // 2. Body should be roughly horizontal (not standing)
        let bodyHorizontal = abs(avgShoulderY - avgHipY) < 0.3
        
        // 3. Not in a standing position (shoulders not too far above hips)
        let notStanding = avgShoulderY > avgHipY - 0.2
        
        return handsOnGround && bodyHorizontal && notStanding
    }
    
    /// Get specific adjustment needed for position
    private func getPositionAdjustment(_ body: DetectedBody) -> String {
        guard let leftWrist = body.point(.leftWrist),
              let rightWrist = body.point(.rightWrist),
              let leftShoulder = body.point(.leftShoulder),
              let rightShoulder = body.point(.rightShoulder) else {
            return "Get into push-up position"
        }
        
        let avgWristY = (leftWrist.location.y + rightWrist.location.y) / 2
        let avgShoulderY = (leftShoulder.location.y + rightShoulder.location.y) / 2
        
        // Check specific issues
        if avgWristY > avgShoulderY {
            return "Place hands on ground"
        }
        
        guard let leftHip = body.point(.leftHip),
              let rightHip = body.point(.rightHip) else {
            return "Lower into push-up"
        }
        
        let avgHipY = (leftHip.location.y + rightHip.location.y) / 2
        
        if avgShoulderY < avgHipY - 0.2 {
            return "Lower into push-up"
        }
        
        return "Get into push-up position"
    }
    
    /// Check for basic form issues (but don't block starting)
    private func checkBasicFormIssues(_ body: DetectedBody) -> [String] {
        var issues: [String] = []
        
        // Use the grader's assessment but don't be too strict
        let gradingResult = exerciseGrader.gradePose(body: body)
        if case .incorrectForm(let feedback) = gradingResult {
            // Only add non-critical feedback
            if !feedback.lowercased().contains("lower") && 
               !feedback.lowercased().contains("bend") {
                issues.append(feedback)
            }
        }
        
        return issues
    }
    
    /// Handle position loss with grace period
    private func handlePositionLoss() {
        if positionLostTime == nil {
            positionLostTime = Date()
        }
        
        // Don't reset immediately - give user time to adjust
        if let lostTime = positionLostTime,
           Date().timeIntervalSince(lostTime) > positionGracePeriod {
            correctPositionStartTime = nil
            positionHoldProgress = 0.0
            positionLostTime = nil
        }
    }
    
    /// Provide audio feedback based on position quality
    private func provideAudioFeedback(for quality: PositionQuality) {
        guard isSoundEnabled else { return }
        
        switch quality {
        case .fair:
            // Play encouraging beep
            AudioServicesPlaySystemSound(1057)
        case .good, .perfect:
            // Play success sound and speak
            AudioServicesPlaySystemSound(1025)
            speakText("Hold steady")
        default:
            break
        }
    }
    
    /// Speak text using text-to-speech
    private func speakText(_ text: String) {
        guard isSoundEnabled else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.volume = 1.0
        speechSynthesizer.speak(utterance)
    }
    
    /// Process detected body and convert to landmarks for position analysis
    private func processDetectedBody(_ body: DetectedBody) {
        // TODO: Re-enable once AutoPositionDetector is available
        // For now, just update the instruction
        DispatchQueue.main.async { [weak self] in
            self?.currentInstruction = "Get into starting position"
            self?.feedbackMessage = "Get into starting position"
        }
    }
    
    /// Handle position detection results with proper type safety
    private func handlePositionDetection(_ detection: Any) {
        // TODO: Re-enable once PositionDetectionResult type is available
        // Update UI based on detection
        // DispatchQueue.main.async { [weak self] in
        //     guard let self = self else { return }
        //     
        //     // Update feedback properties
        //     self.currentInstruction = detection.feedback.primaryInstruction
        //     self.positioningConfidence = detection.feedback.confidenceScore
        //     self.missingRequirements = detection.feedback.missingRequirements
        //     self.feedbackMessage = detection.feedback.primaryInstruction
        //     
        //     // Handle state transitions based on position detection
        //     if self.workoutState == .waitingForPosition {
        //         if detection.isInPosition {
        //             // User is correctly positioned, start countdown
        //             self.handlePositionDetected()
        //         } else {
        //             // Continue showing positioning guidance
        //             self.showPositioningFeedback(detection.feedback)
        //         }
        //     }
        // }
    }
    
    /// Show positioning feedback to user
    private func showPositioningFeedback(_ feedback: Any) {
        // TODO: Re-enable once PositioningFeedback type is available
        // Update UI with positioning guidance
        // self.currentInstruction = feedback.primaryInstruction
        // self.positioningConfidence = feedback.confidenceScore
        // self.missingRequirements = feedback.missingRequirements
        // self.feedbackMessage = feedback.primaryInstruction
    }
    
    /// Start automatic position detection
    func startAutomaticPositionDetection() {
        // autoPositionDetector.isDetecting = true
        // print("DEBUG: [WorkoutSessionViewModel] Started automatic position detection")
    }
    
    /// Stop automatic position detection
    func stopAutomaticPositionDetection() {
        // autoPositionDetector.isDetecting = false
        // print("DEBUG: [WorkoutSessionViewModel] Stopped automatic position detection")
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
        // Get current orientation
        let currentOrientation = UIDevice.current.orientation.interfaceOrientation
        
        // Skip if same as last processed
        guard currentOrientation != lastProcessedOrientation else {
            print("DEBUG: [WorkoutSessionViewModel] Skipping same orientation: \(currentOrientation.rawValue)")
            return
        }
        
        // Cancel any pending orientation change
        orientationChangeDebouncer?.invalidate()
        
        print("DEBUG: [WorkoutSessionViewModel] Scheduling orientation change from \(lastProcessedOrientation?.rawValue ?? 0) to \(currentOrientation.rawValue)")
        
        // Debounce with longer delay to prevent rapid changes
        orientationChangeDebouncer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            // Double-check orientation hasn't changed again
            let finalOrientation = UIDevice.current.orientation.interfaceOrientation
            guard finalOrientation == currentOrientation else {
                print("DEBUG: [WorkoutSessionViewModel] Orientation changed during debounce, skipping")
                return
            }
            
            // Prevent concurrent recalibrations
            guard !self.isRecalibrating else { 
                print("DEBUG: [WorkoutSessionViewModel] Already recalibrating, skipping")
                return 
            }
            
            // Only handle significant orientation changes
            guard finalOrientation.isPortrait || finalOrientation.isLandscape else {
                print("DEBUG: [WorkoutSessionViewModel] Not a valid orientation, skipping")
                return
            }
            
            print("DEBUG: [WorkoutSessionViewModel] Processing orientation change to \(finalOrientation.rawValue)")
            
            // Run the actual orientation change on main queue
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.isRecalibrating = true
                self.lastProcessedOrientation = finalOrientation
                self.lastOrientation = finalOrientation
                self.currentOrientation = finalOrientation
                
                // Note: PoseDetectorService doesn't need explicit stopping - it processes frames as they come
                // Detection will naturally stop when camera frames stop coming
                
                // Important: Give the service time to fully stop
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    guard let self = self else { return }
                    
                    // Update camera orientation
                    self.cameraService.updateOutputOrientation()
                    
                    // Wait for camera to update
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                        guard let self = self else { return }
                        
                        print("DEBUG: [WorkoutSessionViewModel] Reinitializing for new orientation")
                        
                        // Reset grader state
                        self.exerciseGrader.resetState()
                        self.updateUIFromGraderState()
                        
                        // Reload calibration for new orientation
                        Task { @MainActor [weak self] in
                            guard let self = self else { return }
                            await self.checkCalibrationStatus()
                            self.isRecalibrating = false
                            print("DEBUG: [WorkoutSessionViewModel] Orientation change complete")
                        }
                    }
                }
            }
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
            
            // All audio feedback completely removed - no beeps
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
            // Sit-ups are deprecated, redirect to placeholder
            print("Warning: Sit-ups are deprecated. Use plank instead.")
            return WorkoutSessionPlaceholderGrader()
        case .plank:                           // NEW: Add plank case
            return PlankGrader()               // NEW: Use PlankGrader
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
    
    // MARK: - Simplified Calibration Methods
    var isQuickCalibrated: Bool {
        // Always return true since we use quick calibration with smart defaults
        return true
    }
    
    func applyQuickCalibration(from manager: Any) {
        print("DEBUG: [WorkoutSessionViewModel] Applying quick calibration for \(exerciseType.displayName)")
        
        // Create a simplified calibration data using default values
        let quickCalibrationData = createQuickCalibrationData()
        
        // Apply to real-time feedback manager
        realTimeFeedbackManager.startFeedback(for: exerciseType, with: quickCalibrationData)
        
        // Update grader with calibration data if supported
        if let calibratableGrader = exerciseGrader as? CalibratableExerciseGrader {
            calibratableGrader.applyCalibration(quickCalibrationData)
        }
        
        print("DEBUG: [WorkoutSessionViewModel] Quick calibration applied successfully")
    }
    
    private func createQuickCalibrationData() -> CalibrationData {
        // Create default angle adjustments based on exercise type and current orientation
        let currentOrientation = UIDevice.current.orientation
        let angleAdjustments = createDefaultAngleAdjustments(for: exerciseType, orientation: currentOrientation)
        
        // Create default visibility thresholds
        let visibilityThresholds = VisibilityThresholds(
            minimumConfidence: 0.5,
            criticalJoints: 0.6,
            supportJoints: 0.4,
            faceJoints: 0.3
        )
        
        // Create default pose normalization
        let poseNormalization = PoseNormalization(
            shoulderWidth: 0.4,
            hipWidth: 0.3,
            armLength: 0.6,
            legLength: 0.8,
            headSize: 0.15
        )
        
        // Create default validation ranges
        let validationRanges = ValidationRanges(
            angleTolerances: [
                "pushup_elbow": 15.0,
                "situp_torso": 20.0,
                "pullup_arm": 15.0,
                "body_alignment": 25.0
            ],
            positionTolerances: [
                "horizontal_drift": 0.15,
                "vertical_drift": 0.15,
                "distance_variation": 0.25
            ],
            movementThresholds: [
                "max_speed": 35.0,
                "min_speed": 1.5,
                "stability_window": 6.0
            ]
        )
        
        return CalibrationData(
            id: UUID(),
            timestamp: Date(),
            exercise: exerciseType,
            deviceHeight: 1.0, // Default height
            deviceAngle: currentOrientation.isLandscape ? 90.0 : 0.0,
            deviceDistance: getDefaultOptimalDistance(for: exerciseType),
            deviceStability: 0.8, // Assume good stability for quick calibration
            userHeight: 1.7, // Average height
            armSpan: 1.7, // Approximate arm span
            torsoLength: 0.6, // Approximate torso length
            legLength: 0.9, // Approximate leg length
            angleAdjustments: angleAdjustments,
            visibilityThresholds: visibilityThresholds,
            poseNormalization: poseNormalization,
            calibrationScore: 75.0, // Good default score
            confidenceLevel: 0.75,
            frameCount: 0, // No frames collected for quick calibration
            validationRanges: validationRanges
        )
    }
    
    private func createDefaultAngleAdjustments(for exercise: ExerciseType, orientation: UIDeviceOrientation) -> AngleAdjustments {
        // Adjust angles based on exercise and orientation
        let orientationAdjustment: Float = orientation.isLandscape ? 5.0 : 0.0
        
        switch exercise {
        case .pushup:
            return AngleAdjustments(
                pushupElbowUp: 170.0 + orientationAdjustment,
                pushupElbowDown: 90.0 - orientationAdjustment,
                pushupBodyAlignment: 20.0 + orientationAdjustment,
                situpTorsoUp: 90.0,
                situpTorsoDown: 45.0,
                situpKneeAngle: 90.0,
                pullupArmExtended: 170.0,
                pullupArmFlexed: 90.0,
                pullupBodyVertical: 15.0
            )
        case .situp:
            return AngleAdjustments(
                pushupElbowUp: 170.0,
                pushupElbowDown: 90.0,
                pushupBodyAlignment: 20.0,
                situpTorsoUp: 90.0 + orientationAdjustment,
                situpTorsoDown: 45.0 - orientationAdjustment,
                situpKneeAngle: 90.0,
                pullupArmExtended: 170.0,
                pullupArmFlexed: 90.0,
                pullupBodyVertical: 15.0
            )
        case .pullup:
            return AngleAdjustments(
                pushupElbowUp: 170.0,
                pushupElbowDown: 90.0,
                pushupBodyAlignment: 20.0,
                situpTorsoUp: 90.0,
                situpTorsoDown: 45.0,
                situpKneeAngle: 90.0,
                pullupArmExtended: 170.0 + orientationAdjustment,
                pullupArmFlexed: 90.0 - orientationAdjustment,
                pullupBodyVertical: 15.0 + orientationAdjustment
            )
        default:
            return AngleAdjustments(
                pushupElbowUp: 170.0,
                pushupElbowDown: 90.0,
                pushupBodyAlignment: 20.0,
                situpTorsoUp: 90.0,
                situpTorsoDown: 45.0,
                situpKneeAngle: 90.0,
                pullupArmExtended: 170.0,
                pullupArmFlexed: 90.0,
                pullupBodyVertical: 15.0
            )
        }
    }
    
    func updateQuickCalibrationForOrientation(_ manager: Any) {
        // Simply reapply quick calibration with current orientation
        applyQuickCalibration(from: manager)
    }
    
    private func getDefaultOptimalDistance(for exercise: ExerciseType) -> Float {
        switch exercise {
        case .pushup:
            return UIDevice.current.orientation.isLandscape ? 2.5 : 3.0
        case .situp:
            return UIDevice.current.orientation.isLandscape ? 2.8 : 3.2
        case .pullup:
            return UIDevice.current.orientation.isLandscape ? 3.5 : 4.0
        default:
            return 2.5
        }
    }
}

// MARK: - UIDeviceOrientation Extension
extension UIDeviceOrientation {
    var interfaceOrientation: UIInterfaceOrientation {
        switch self {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight // Note: Device and interface orientations are opposite
        case .landscapeRight:
            return .landscapeLeft  // Note: Device and interface orientations are opposite
        default:
            return .portrait
        }
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
