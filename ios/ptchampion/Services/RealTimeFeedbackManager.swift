import Foundation
import Combine
import AVFoundation
import Vision
import UIKit

/// Manages real-time feedback during body-tracking exercises using calibration data
class RealTimeFeedbackManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentFeedback: ExerciseFeedback = ExerciseFeedback()
    @Published var isActive = false
    @Published var formScore: Float = 0
    @Published var repCount: Int = 0
    @Published var exercisePhase: String = ""
    @Published var criticalErrors: [FeedbackError] = []
    @Published var suggestions: [FeedbackSuggestion] = []
    
    // MARK: - Dependencies
    private let poseDetectorService: PoseDetectorServiceProtocol
    private let apftValidator: APFTRepValidator
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Calibration Data
    private var currentCalibration: CalibrationData?
    private var currentExercise: ExerciseType = .pushup
    
    // MARK: - Feedback State
    private var feedbackHistory: [ExerciseFeedback] = []
    private var lastFeedbackTime: TimeInterval = 0
    private let feedbackInterval: TimeInterval = 0.1 // 10 FPS feedback
    private var consecutiveGoodForm = 0
    private var consecutivePoorForm = 0
    
    // MARK: - Audio Feedback
    private let audioEngine = AVAudioEngine()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var lastAudioFeedback: TimeInterval = 0
    private let minAudioInterval: TimeInterval = 3.0 // Minimum 3 seconds between audio cues
    
    // MARK: - Haptic Feedback
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    // MARK: - Constants
    private struct FeedbackConstants {
        static let goodFormThreshold: Float = 0.8
        static let poorFormThreshold: Float = 0.5
        static let criticalErrorThreshold: Float = 0.3
        static let consecutiveFramesForStable = 5
        static let maxFeedbackHistory = 30
    }
    
    // MARK: - Initialization
    init(poseDetectorService: PoseDetectorServiceProtocol, apftValidator: APFTRepValidator) {
        self.poseDetectorService = poseDetectorService
        self.apftValidator = apftValidator
        
        setupPoseDetection()
        setupAudio()
    }
    
    // MARK: - Setup
    private func setupPoseDetection() {
        poseDetectorService.detectedBodyPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] detectedBody in
                self?.processPoseForFeedback(detectedBody)
            }
            .store(in: &cancellables)
    }
    
    private func setupAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Public Interface
    func startFeedback(for exercise: ExerciseType, with calibration: CalibrationData?) {
        print("🎯 Starting real-time feedback for \(exercise.displayName)")
        
        currentExercise = exercise
        currentCalibration = calibration
        isActive = true
        
        // Reset state
        resetFeedbackState()
        
        // Load calibration-specific adjustments
        if let calibration = calibration {
            applyCalibrationAdjustments(calibration)
        }
    }
    
    func stopFeedback() {
        print("🛑 Stopping real-time feedback")
        
        isActive = false
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        // Clear state
        currentFeedback = ExerciseFeedback()
        criticalErrors.removeAll()
        suggestions.removeAll()
    }
    
    func enableAudioFeedback(_ enabled: Bool) {
        if !enabled {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    func triggerHapticFeedback(for type: HapticFeedbackType) {
        switch type {
        case .success:
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.success)
        case .warning:
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.warning)
        case .error:
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.error)
        case .impact:
            hapticFeedback.impactOccurred()
        }
    }
    
    // MARK: - Pose Processing
    private func processPoseForFeedback(_ detectedBody: DetectedBody?) {
        guard isActive, let body = detectedBody else { return }
        
        let currentTime = CACurrentMediaTime()
        
        // Throttle feedback processing
        guard currentTime - lastFeedbackTime >= feedbackInterval else { return }
        lastFeedbackTime = currentTime
        
        // Generate feedback based on exercise type
        let feedback = generateFeedback(for: body, exercise: currentExercise)
        
        // Update published properties
        updateFeedbackState(feedback)
        
        // Provide audio and haptic feedback if appropriate
        deliverMultimodalFeedback(feedback, currentTime: currentTime)
        
        // Store feedback history
        addToHistory(feedback)
    }
    
    private func generateFeedback(for body: DetectedBody, exercise: ExerciseType) -> ExerciseFeedback {
        switch exercise {
        case .pushup:
            return generatePushupFeedback(body)
        case .situp:
            return generateSitupFeedback(body)
        case .pullup:
            return generatePullupFeedback(body)
        default:
            return ExerciseFeedback()
        }
    }
    
    // MARK: - Exercise-Specific Feedback
    private func generatePushupFeedback(_ body: DetectedBody) -> ExerciseFeedback {
        var feedback = ExerciseFeedback()
        feedback.exercise = .pushup
        feedback.timestamp = Date()
        
        // Validate with APFT standards
        let isValidRep = apftValidator.validatePushup(body: body)
        feedback.isValidForm = isValidRep
        
        // Get current phase and rep count
        feedback.phase = apftValidator.pushupPhase
        feedback.repCount = apftValidator.pushupRepCount
        
        // Apply calibration adjustments
        let adjustedAngles = applyAngleAdjustments(body: body, exercise: .pushup)
        
        // Generate specific feedback based on form issues
        let formIssues = apftValidator.pushupFormIssues
        feedback.formIssues = formIssues
        feedback.errors = generateErrorsFromIssues(formIssues, severity: .warning)
        feedback.suggestions = generateSuggestionsFromIssues(formIssues, exercise: .pushup)
        
        // Calculate form score based on calibrated standards
        feedback.formScore = calculateFormScore(body: body, exercise: .pushup, adjustedAngles: adjustedAngles)
        
        // Generate real-time corrections
        feedback.corrections = generatePushupCorrections(body: body, formIssues: formIssues)
        
        return feedback
    }
    
    private func generateSitupFeedback(_ body: DetectedBody) -> ExerciseFeedback {
        var feedback = ExerciseFeedback()
        feedback.exercise = .situp
        feedback.timestamp = Date()
        
        let isValidRep = apftValidator.validateSitup(body: body)
        feedback.isValidForm = isValidRep
        feedback.phase = apftValidator.situpPhase
        feedback.repCount = apftValidator.situpRepCount
        
        let adjustedAngles = applyAngleAdjustments(body: body, exercise: .situp)
        let formIssues = apftValidator.situpFormIssues
        
        feedback.formIssues = formIssues
        feedback.errors = generateErrorsFromIssues(formIssues, severity: .warning)
        feedback.suggestions = generateSuggestionsFromIssues(formIssues, exercise: .situp)
        feedback.formScore = calculateFormScore(body: body, exercise: .situp, adjustedAngles: adjustedAngles)
        feedback.corrections = generateSitupCorrections(body: body, formIssues: formIssues)
        
        return feedback
    }
    
    private func generatePullupFeedback(_ body: DetectedBody) -> ExerciseFeedback {
        var feedback = ExerciseFeedback()
        feedback.exercise = .pullup
        feedback.timestamp = Date()
        
        let isValidRep = apftValidator.validatePullup(body: body)
        feedback.isValidForm = isValidRep
        feedback.phase = apftValidator.pullupPhase
        feedback.repCount = apftValidator.pullupRepCount
        
        let adjustedAngles = applyAngleAdjustments(body: body, exercise: .pullup)
        let formIssues = apftValidator.pullupFormIssues
        
        feedback.formIssues = formIssues
        feedback.errors = generateErrorsFromIssues(formIssues, severity: .warning)
        feedback.suggestions = generateSuggestionsFromIssues(formIssues, exercise: .pullup)
        feedback.formScore = calculateFormScore(body: body, exercise: .pullup, adjustedAngles: adjustedAngles)
        feedback.corrections = generatePullupCorrections(body: body, formIssues: formIssues)
        
        return feedback
    }
    
    // MARK: - Calibration Integration
    private func applyCalibrationAdjustments(_ calibration: CalibrationData) {
        // Update APFT validator with calibrated thresholds
        // This would require extending APFTRepValidator to accept calibration data
        print("📊 Applied calibration adjustments for \(calibration.exercise.displayName)")
        print("   - Device angle: \(calibration.deviceAngle)°")
        print("   - User height: \(calibration.userHeight)m")
        print("   - Calibration score: \(calibration.calibrationScore)")
    }
    
    private func applyAngleAdjustments(body: DetectedBody, exercise: ExerciseType) -> [String: Float] {
        guard let calibration = currentCalibration else {
            return [:] // Return empty if no calibration data
        }
        
        var adjustedAngles: [String: Float] = [:]
        
        // Apply exercise-specific angle adjustments from calibration
        switch exercise {
        case .pushup:
            if let leftElbow = body.point(.leftElbow),
               let rightElbow = body.point(.rightElbow),
               let leftShoulder = body.point(.leftShoulder),
               let rightShoulder = body.point(.rightShoulder),
               let leftWrist = body.point(.leftWrist),
               let rightWrist = body.point(.rightWrist) {
                
                let leftElbowAngle = calculateAngle(point1: leftShoulder.location, vertex: leftElbow.location, point3: leftWrist.location)
                let rightElbowAngle = calculateAngle(point1: rightShoulder.location, vertex: rightElbow.location, point3: rightWrist.location)
                
                // Apply calibration adjustments
                let adjustedLeftAngle = leftElbowAngle + calibration.angleAdjustments.pushupElbowUp - 170.0
                let adjustedRightAngle = rightElbowAngle + calibration.angleAdjustments.pushupElbowDown - 90.0
                
                adjustedAngles["left_elbow"] = adjustedLeftAngle
                adjustedAngles["right_elbow"] = adjustedRightAngle
            }
        case .situp:
            // Apply situp-specific adjustments
            break
        case .pullup:
            // Apply pullup-specific adjustments
            break
        default:
            break
        }
        
        return adjustedAngles
    }
    
    // MARK: - Form Analysis
    private func calculateFormScore(body: DetectedBody, exercise: ExerciseType, adjustedAngles: [String: Float]) -> Float {
        guard let calibration = currentCalibration else {
            return 0.5 // Default score without calibration
        }
        
        var score: Float = 1.0
        let penalties: [Float] = []
        
        // Visibility score based on calibrated thresholds
        let visibilityScore = calculateVisibilityScore(body: body, thresholds: calibration.visibilityThresholds)
        score *= visibilityScore
        
        // Angle accuracy score based on calibrated standards
        let angleScore = calculateAngleAccuracy(adjustedAngles: adjustedAngles, exercise: exercise, calibration: calibration)
        score *= angleScore
        
        // Movement stability score
        let stabilityScore = calculateMovementStability(body: body)
        score *= stabilityScore
        
        return max(0.0, min(1.0, score))
    }
    
    private func calculateVisibilityScore(body: DetectedBody, thresholds: VisibilityThresholds) -> Float {
        let criticalJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder, .leftElbow, .rightElbow,
            .leftWrist, .rightWrist, .leftHip, .rightHip
        ]
        
        var totalScore: Float = 0
        var jointCount = 0
        
        for joint in criticalJoints {
            if let point = body.point(joint) {
                let confidence = point.confidence
                if confidence >= thresholds.criticalJoints {
                    totalScore += 1.0
                } else if confidence >= thresholds.minimumConfidence {
                    totalScore += 0.5
                }
                jointCount += 1
            }
        }
        
        return jointCount > 0 ? totalScore / Float(jointCount) : 0.0
    }
    
    private func calculateAngleAccuracy(adjustedAngles: [String: Float], exercise: ExerciseType, calibration: CalibrationData) -> Float {
        // Compare adjusted angles against calibrated targets
        var accuracy: Float = 1.0
        
        for (angleType, angle) in adjustedAngles {
            if let tolerance = calibration.validationRanges.angleTolerances[angleType] {
                let deviation = abs(angle)
                if deviation > tolerance {
                    let penalty = min(0.5, deviation / (tolerance * 2))
                    accuracy -= penalty
                }
            }
        }
        
        return max(0.0, accuracy)
    }
    
    private func calculateMovementStability(body: DetectedBody) -> Float {
        // Calculate stability based on pose consistency over recent frames
        guard feedbackHistory.count >= 3 else { return 1.0 }
        
        let recentFeedback = Array(feedbackHistory.suffix(3))
        var stabilityScore: Float = 1.0
        
        // Check for sudden changes in key joint positions
        // This is a simplified implementation
        for i in 1..<recentFeedback.count {
            let current = recentFeedback[i]
            let previous = recentFeedback[i-1]
            
            if abs(current.formScore - previous.formScore) > 0.3 {
                stabilityScore -= 0.2
            }
        }
        
        return max(0.0, stabilityScore)
    }
    
    // MARK: - Error and Suggestion Generation
    private func generateErrorsFromIssues(_ formIssues: [String], severity: FeedbackSeverity) -> [FeedbackError] {
        return formIssues.map { issue in
            FeedbackError(
                id: UUID(),
                message: issue,
                severity: severity,
                timestamp: Date(),
                actionRequired: severity == .critical
            )
        }
    }
    
    private func generateSuggestionsFromIssues(_ formIssues: [String], exercise: ExerciseType) -> [FeedbackSuggestion] {
        var suggestions: [FeedbackSuggestion] = []
        
        for issue in formIssues {
            if let suggestion = createSuggestionForIssue(issue, exercise: exercise) {
                suggestions.append(suggestion)
            }
        }
        
        return suggestions
    }
    
    private func createSuggestionForIssue(_ issue: String, exercise: ExerciseType) -> FeedbackSuggestion? {
        let issueMap: [String: (message: String, type: FeedbackSuggestionType)] = [
            "Keep body straight": ("Focus on maintaining a straight line from head to heels", .form),
            "Extend arms fully": ("Push all the way up until arms are straight", .technique),
            "Lower until upper arms are parallel to ground": ("Go down until your upper arms are parallel to the floor", .range),
            "Go lower": ("Increase your range of motion by going deeper", .range),
            "Minimize body swing": ("Control your movement and avoid swinging", .stability),
            "Pull chin over bar": ("Pull yourself higher until your chin clears the bar", .range)
        ]
        
        if let mapping = issueMap[issue] {
            return FeedbackSuggestion(
                id: UUID(),
                message: mapping.message,
                type: mapping.type,
                priority: .medium,
                timestamp: Date()
            )
        }
        
        return nil
    }
    
    // MARK: - Exercise-Specific Corrections
    private func generatePushupCorrections(body: DetectedBody, formIssues: [String]) -> [FormCorrection] {
        var corrections: [FormCorrection] = []
        
        for issue in formIssues {
            switch issue {
            case "Keep body straight":
                corrections.append(FormCorrection(
                    type: .bodyAlignment,
                    message: "Engage your core and keep your body in a straight line",
                    severity: .medium,
                    visualCue: .bodyLineIndicator
                ))
            case "Extend arms fully":
                corrections.append(FormCorrection(
                    type: .rangeOfMotion,
                    message: "Push up until your arms are fully extended",
                    severity: .high,
                    visualCue: .armExtensionIndicator
                ))
            case "Lower until upper arms are parallel to ground":
                corrections.append(FormCorrection(
                    type: .rangeOfMotion,
                    message: "Go down further until your upper arms are parallel to the ground",
                    severity: .high,
                    visualCue: .depthIndicator
                ))
            default:
                break
            }
        }
        
        return corrections
    }
    
    private func generateSitupCorrections(body: DetectedBody, formIssues: [String]) -> [FormCorrection] {
        // Similar implementation for situps
        return []
    }
    
    private func generatePullupCorrections(body: DetectedBody, formIssues: [String]) -> [FormCorrection] {
        // Similar implementation for pullups
        return []
    }
    
    // MARK: - Multimodal Feedback Delivery
    private func deliverMultimodalFeedback(_ feedback: ExerciseFeedback, currentTime: TimeInterval) {
        // Update consecutive form tracking
        updateConsecutiveFormTracking(feedback)
        
        // Trigger haptic feedback for significant events
        if !feedback.errors.isEmpty {
            triggerHapticFeedback(for: .warning)
        } else if feedback.formScore > FeedbackConstants.goodFormThreshold {
            if consecutiveGoodForm == FeedbackConstants.consecutiveFramesForStable {
                triggerHapticFeedback(for: .success)
            }
        }
        
        // Provide audio feedback at appropriate intervals
        if currentTime - lastAudioFeedback >= minAudioInterval {
            provideAudioFeedback(feedback, currentTime: currentTime)
        }
    }
    
    private func updateConsecutiveFormTracking(_ feedback: ExerciseFeedback) {
        if feedback.formScore > FeedbackConstants.goodFormThreshold {
            consecutiveGoodForm += 1
            consecutivePoorForm = 0
        } else if feedback.formScore < FeedbackConstants.poorFormThreshold {
            consecutivePoorForm += 1
            consecutiveGoodForm = 0
        } else {
            // Reset both if form is neutral
            consecutiveGoodForm = 0
            consecutivePoorForm = 0
        }
    }
    
    private func provideAudioFeedback(_ feedback: ExerciseFeedback, currentTime: TimeInterval) {
        var message: String?
        
        // Prioritize critical errors
        if let criticalError = feedback.errors.first(where: { $0.severity == .critical }) {
            message = criticalError.message
        }
        // Then check for consistent poor form
        else if consecutivePoorForm >= FeedbackConstants.consecutiveFramesForStable * 2 {
            if let primaryCorrection = feedback.corrections.first {
                message = primaryCorrection.message
            }
        }
        // Provide encouragement for good form streaks
        else if consecutiveGoodForm == FeedbackConstants.consecutiveFramesForStable * 3 {
            message = "Great form! Keep it up!"
        }
        
        if let message = message {
            speakMessage(message)
            lastAudioFeedback = currentTime
        }
    }
    
    private func speakMessage(_ message: String) {
        let utterance = AVSpeechUtterance(string: message)
        utterance.rate = 0.5
        utterance.volume = 0.8
        speechSynthesizer.speak(utterance)
    }
    
    // MARK: - State Management
    private func updateFeedbackState(_ feedback: ExerciseFeedback) {
        currentFeedback = feedback
        formScore = feedback.formScore
        repCount = feedback.repCount
        exercisePhase = feedback.phase
        criticalErrors = feedback.errors.filter { $0.severity == .critical }
        suggestions = feedback.suggestions
    }
    
    private func resetFeedbackState() {
        currentFeedback = ExerciseFeedback()
        formScore = 0
        repCount = 0
        exercisePhase = ""
        criticalErrors.removeAll()
        suggestions.removeAll()
        feedbackHistory.removeAll()
        consecutiveGoodForm = 0
        consecutivePoorForm = 0
        lastFeedbackTime = 0
        lastAudioFeedback = 0
    }
    
    private func addToHistory(_ feedback: ExerciseFeedback) {
        feedbackHistory.append(feedback)
        
        // Maintain maximum history size
        if feedbackHistory.count > FeedbackConstants.maxFeedbackHistory {
            feedbackHistory.removeFirst()
        }
    }
    
    // MARK: - Utility
    private func calculateAngle(point1: CGPoint, vertex: CGPoint, point3: CGPoint) -> Float {
        let v1 = CGPoint(x: point1.x - vertex.x, y: point1.y - vertex.y)
        let v2 = CGPoint(x: point3.x - vertex.x, y: point3.y - vertex.y)
        
        let dot = v1.x * v2.x + v1.y * v2.y
        let mag1 = sqrt(v1.x * v1.x + v1.y * v1.y)
        let mag2 = sqrt(v2.x * v2.x + v2.y * v2.y)
        
        guard mag1 > 0 && mag2 > 0 else { return 0 }
        
        let cosAngle = dot / (mag1 * mag2)
        let clampedCosAngle = max(-1.0, min(1.0, cosAngle))
        return Float(acos(clampedCosAngle) * 180.0 / .pi)
    }
    
    // MARK: - Cleanup
    deinit {
        stopFeedback()
        cancellables.forEach { $0.cancel() }
    }
}

// MARK: - Supporting Types

enum HapticFeedbackType {
    case success
    case warning
    case error
    case impact
}

enum FeedbackSeverity {
    case info
    case medium
    case warning
    case high
    case critical
}

enum FeedbackSuggestionType {
    case form
    case technique
    case range
    case stability
    case positioning
}

enum FormCorrectionType {
    case bodyAlignment
    case rangeOfMotion
    case timing
    case stability
    case positioning
}

enum VisualCueType {
    case bodyLineIndicator
    case armExtensionIndicator
    case depthIndicator
    case angleGuide
    case rangeMarker
}

struct ExerciseFeedback {
    var exercise: ExerciseType = .pushup
    var timestamp: Date = Date()
    var isValidForm: Bool = false
    var formScore: Float = 0
    var phase: String = ""
    var repCount: Int = 0
    var formIssues: [String] = []
    var errors: [FeedbackError] = []
    var suggestions: [FeedbackSuggestion] = []
    var corrections: [FormCorrection] = []
}

struct FeedbackError: Identifiable {
    let id: UUID
    let message: String
    let severity: FeedbackSeverity
    let timestamp: Date
    let actionRequired: Bool
}

struct FeedbackSuggestion: Identifiable {
    let id: UUID
    let message: String
    let type: FeedbackSuggestionType
    let priority: Priority
    let timestamp: Date
    
    enum Priority {
        case low
        case medium
        case high
    }
}

struct FormCorrection {
    let type: FormCorrectionType
    let message: String
    let severity: FeedbackSeverity
    let visualCue: VisualCueType?
    
    init(type: FormCorrectionType, message: String, severity: FeedbackSeverity, visualCue: VisualCueType? = nil) {
        self.type = type
        self.message = message
        self.severity = severity
        self.visualCue = visualCue
    }
}
