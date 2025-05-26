import Foundation
import Combine
import AVFoundation
import Vision

// MARK: - Calibration Strategy Protocol

/// Protocol for different calibration strategies
protocol CalibrationStrategy {
    var strategyName: String { get }
    var minimumRequiredJoints: [VNHumanBodyPoseObservation.JointName] { get }
    var requiredFrames: Int { get }
    var minimumConfidence: Float { get }
    
    func canExecute(with detectedBody: DetectedBody?) -> Bool
    func performCalibration(frames: [CalibrationFrame], exercise: ExerciseType) -> CalibrationData?
    func getInstructions() -> String
}

// MARK: - Full Body Calibration Strategy

/// Standard full-body calibration requiring all major joints
class FullBodyCalibrationStrategy: CalibrationStrategy {
    let strategyName = "Full Body Calibration"
    
    let minimumRequiredJoints: [VNHumanBodyPoseObservation.JointName] = [
        .nose, .leftShoulder, .rightShoulder, .leftElbow, .rightElbow,
        .leftWrist, .rightWrist, .leftHip, .rightHip, .leftKnee,
        .rightKnee, .leftAnkle, .rightAnkle
    ]
    
    let requiredFrames = 60
    let minimumConfidence: Float = 0.5
    
    func canExecute(with detectedBody: DetectedBody?) -> Bool {
        guard let body = detectedBody else { return false }
        
        let visibleJoints = minimumRequiredJoints.filter { joint in
            body.point(joint)?.confidence ?? 0 > minimumConfidence
        }
        
        return Float(visibleJoints.count) / Float(minimumRequiredJoints.count) > 0.85
    }
    
    func performCalibration(frames: [CalibrationFrame], exercise: ExerciseType) -> CalibrationData? {
        // Use standard calibration logic from CalibrationManager
        guard frames.count >= requiredFrames else { return nil }
        
        // Calculate measurements
        let measurements = calculateMeasurements(from: frames)
        let deviceMetrics = calculateDeviceMetrics(from: frames)
        
        return CalibrationData(
            id: UUID(),
            timestamp: Date(),
            exercise: exercise,
            deviceHeight: deviceMetrics.height,
            deviceAngle: deviceMetrics.angle,
            deviceDistance: deviceMetrics.distance,
            deviceStability: deviceMetrics.stability,
            userHeight: measurements.height,
            armSpan: measurements.armSpan,
            torsoLength: measurements.torsoLength,
            legLength: measurements.legLength,
            angleAdjustments: calculateAngleAdjustments(for: exercise, measurements: measurements),
            visibilityThresholds: VisibilityThresholds(
                minimumConfidence: 0.5,
                criticalJoints: 0.55,
                supportJoints: 0.45,
                faceJoints: 0.35
            ),
            poseNormalization: calculateNormalization(measurements),
            calibrationScore: 90.0,
            confidenceLevel: 0.9,
            frameCount: frames.count,
            validationRanges: createValidationRanges(for: exercise)
        )
    }
    
    func getInstructions() -> String {
        "Stand where your full body is visible in the camera frame. We'll analyze your body proportions for accurate exercise tracking."
    }
    
    // Helper methods
    private func calculateMeasurements(from frames: [CalibrationFrame]) -> (height: Float, armSpan: Float, torsoLength: Float, legLength: Float) {
        // Simplified calculation - in production would be more sophisticated
        var heights: [Float] = []
        var armSpans: [Float] = []
        
        for frame in frames {
            let body = frame.poseData
            
            if let nose = body.point(.nose),
               let leftAnkle = body.point(.leftAnkle),
               let rightAnkle = body.point(.rightAnkle) {
                let ankleY = (leftAnkle.location.y + rightAnkle.location.y) / 2
                heights.append(Float(abs(nose.location.y - ankleY)))
            }
            
            if let leftWrist = body.point(.leftWrist),
               let rightWrist = body.point(.rightWrist) {
                armSpans.append(Float(abs(leftWrist.location.x - rightWrist.location.x)))
            }
        }
        
        let avgHeight = heights.isEmpty ? 0.5 : heights.reduce(0, +) / Float(heights.count)
        let avgArmSpan = armSpans.isEmpty ? 0.5 : armSpans.reduce(0, +) / Float(armSpans.count)
        
        return (avgHeight, avgArmSpan, avgHeight * 0.35, avgHeight * 0.53)
    }
    
    private func calculateDeviceMetrics(from frames: [CalibrationFrame]) -> (height: Float, angle: Float, distance: Float, stability: Float) {
        // Simplified calculation
        let avgStability = frames.map { $0.frameQuality.stability }.reduce(0, +) / Float(frames.count)
        return (1.0, 30.0, 1.5, avgStability)
    }
    
    private func calculateAngleAdjustments(for exercise: ExerciseType, measurements: (height: Float, armSpan: Float, torsoLength: Float, legLength: Float)) -> AngleAdjustments {
        // Return standard angles
        return AngleAdjustments(
            pushupElbowUp: 170,
            pushupElbowDown: 90,
            pushupBodyAlignment: 15,
            situpTorsoUp: 90,
            situpTorsoDown: 45,
            situpKneeAngle: 90,
            pullupArmExtended: 170,
            pullupArmFlexed: 90,
            pullupBodyVertical: 10
        )
    }
    
    private func calculateNormalization(_ measurements: (height: Float, armSpan: Float, torsoLength: Float, legLength: Float)) -> PoseNormalization {
        return PoseNormalization(
            shoulderWidth: measurements.armSpan * 0.2,
            hipWidth: measurements.armSpan * 0.15,
            armLength: measurements.armSpan * 0.5,
            legLength: measurements.legLength,
            headSize: measurements.height * 0.13
        )
    }
    
    private func createValidationRanges(for exercise: ExerciseType) -> ValidationRanges {
        return ValidationRanges(
            angleTolerances: ["default": 15.0],
            positionTolerances: ["drift": 0.15],
            movementThresholds: ["speed": 30.0]
        )
    }
}

// MARK: - Partial Body Calibration Strategy

/// Calibration using only torso and relevant limbs for the exercise
class PartialBodyCalibrationStrategy: CalibrationStrategy {
    let strategyName = "Partial Body Calibration"
    let exercise: ExerciseType
    
    var minimumRequiredJoints: [VNHumanBodyPoseObservation.JointName] {
        switch exercise {
        case .pushup:
            return [.leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist, .leftHip, .rightHip]
        case .situp:
            return [.leftShoulder, .rightShoulder, .leftHip, .rightHip, .leftKnee, .rightKnee]
        case .pullup:
            return [.leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist]
        default:
            return [.leftShoulder, .rightShoulder, .leftHip, .rightHip]
        }
    }
    
    let requiredFrames = 40
    let minimumConfidence: Float = 0.55
    
    init(exercise: ExerciseType) {
        self.exercise = exercise
    }
    
    func canExecute(with detectedBody: DetectedBody?) -> Bool {
        guard let body = detectedBody else { return false }
        
        let visibleJoints = minimumRequiredJoints.filter { joint in
            body.point(joint)?.confidence ?? 0 > minimumConfidence
        }
        
        return Float(visibleJoints.count) / Float(minimumRequiredJoints.count) > 0.75
    }
    
    func performCalibration(frames: [CalibrationFrame], exercise: ExerciseType) -> CalibrationData? {
        guard frames.count >= requiredFrames else { return nil }
        
        // Use default profiles with adjustments based on visible joints
        var baseCalibration = DefaultCalibrationProfiles.getDefault(for: exercise)
        
        // Adjust confidence based on partial visibility
        baseCalibration = CalibrationData(
            id: baseCalibration.id,
            timestamp: Date(),
            exercise: exercise,
            deviceHeight: baseCalibration.deviceHeight,
            deviceAngle: baseCalibration.deviceAngle,
            deviceDistance: baseCalibration.deviceDistance,
            deviceStability: calculateStability(from: frames),
            userHeight: baseCalibration.userHeight,
            armSpan: baseCalibration.armSpan,
            torsoLength: baseCalibration.torsoLength,
            legLength: baseCalibration.legLength,
            angleAdjustments: baseCalibration.angleAdjustments,
            visibilityThresholds: VisibilityThresholds(
                minimumConfidence: 0.55,
                criticalJoints: 0.6,
                supportJoints: 0.5,
                faceJoints: 0.4
            ),
            poseNormalization: baseCalibration.poseNormalization,
            calibrationScore: 75.0,
            confidenceLevel: 0.75,
            frameCount: frames.count,
            validationRanges: baseCalibration.validationRanges
        )
        
        return baseCalibration
    }
    
    func getInstructions() -> String {
        switch exercise {
        case .pushup:
            return "Position your upper body and arms in the camera view. We'll use partial body tracking for calibration."
        case .situp:
            return "Make sure your torso and knees are visible. We'll calibrate using your core body position."
        case .pullup:
            return "Focus on showing your arms and shoulders. We'll calibrate based on upper body movement."
        default:
            return "Position the relevant body parts for your exercise in view."
        }
    }
    
    private func calculateStability(from frames: [CalibrationFrame]) -> Float {
        let stabilities = frames.map { $0.frameQuality.stability }
        return stabilities.reduce(0, +) / Float(stabilities.count)
    }
}

// MARK: - Key Point Calibration Strategy

/// Minimal calibration using only critical joints
class KeyPointCalibrationStrategy: CalibrationStrategy {
    let strategyName = "Key Point Calibration"
    let exercise: ExerciseType
    
    var minimumRequiredJoints: [VNHumanBodyPoseObservation.JointName] {
        switch exercise {
        case .pushup:
            return [.leftShoulder, .rightShoulder, .leftElbow, .rightElbow]
        case .situp:
            return [.leftShoulder, .rightShoulder, .leftHip, .rightHip]
        case .pullup:
            return [.leftWrist, .rightWrist, .leftElbow, .rightElbow]
        default:
            return [.leftShoulder, .rightShoulder]
        }
    }
    
    let requiredFrames = 20
    let minimumConfidence: Float = 0.6
    
    init(exercise: ExerciseType) {
        self.exercise = exercise
    }
    
    func canExecute(with detectedBody: DetectedBody?) -> Bool {
        guard let body = detectedBody else { return false }
        
        let visibleJoints = minimumRequiredJoints.filter { joint in
            body.point(joint)?.confidence ?? 0 > minimumConfidence
        }
        
        return visibleJoints.count >= minimumRequiredJoints.count / 2
    }
    
    func performCalibration(frames: [CalibrationFrame], exercise: ExerciseType) -> CalibrationData? {
        guard frames.count >= requiredFrames else { return nil }
        
        // Use default profiles with reduced confidence
        var baseCalibration = DefaultCalibrationProfiles.getDefault(for: exercise)
        
        return CalibrationData(
            id: UUID(),
            timestamp: Date(),
            exercise: exercise,
            deviceHeight: baseCalibration.deviceHeight,
            deviceAngle: baseCalibration.deviceAngle,
            deviceDistance: baseCalibration.deviceDistance,
            deviceStability: 0.7,
            userHeight: baseCalibration.userHeight,
            armSpan: baseCalibration.armSpan,
            torsoLength: baseCalibration.torsoLength,
            legLength: baseCalibration.legLength,
            angleAdjustments: getRelaxedAngleAdjustments(for: exercise),
            visibilityThresholds: VisibilityThresholds(
                minimumConfidence: 0.6,
                criticalJoints: 0.65,
                supportJoints: 0.55,
                faceJoints: 0.45
            ),
            poseNormalization: baseCalibration.poseNormalization,
            calibrationScore: 65.0,
            confidenceLevel: 0.65,
            frameCount: frames.count,
            validationRanges: getRelaxedValidationRanges(for: exercise)
        )
    }
    
    func getInstructions() -> String {
        "Basic calibration mode - show only the key body parts needed for \(exercise.displayName). Tracking may be less accurate."
    }
    
    private func getRelaxedAngleAdjustments(for exercise: ExerciseType) -> AngleAdjustments {
        // More tolerant angles for minimal tracking
        return AngleAdjustments(
            pushupElbowUp: 160,
            pushupElbowDown: 100,
            pushupBodyAlignment: 25,
            situpTorsoUp: 85,
            situpTorsoDown: 50,
            situpKneeAngle: 85,
            pullupArmExtended: 160,
            pullupArmFlexed: 100,
            pullupBodyVertical: 20
        )
    }
    
    private func getRelaxedValidationRanges(for exercise: ExerciseType) -> ValidationRanges {
        return ValidationRanges(
            angleTolerances: ["default": 20.0],
            positionTolerances: ["drift": 0.25],
            movementThresholds: ["speed": 35.0]
        )
    }
}

// MARK: - Manual Calibration Strategy

/// User-guided manual calibration when automatic detection fails
class ManualCalibrationStrategy: CalibrationStrategy {
    let strategyName = "Manual Setup"
    let minimumRequiredJoints: [VNHumanBodyPoseObservation.JointName] = []
    let requiredFrames = 0
    let minimumConfidence: Float = 0.0
    
    private var userInputs: ManualCalibrationInputs?
    
    struct ManualCalibrationInputs {
        let deviceHeight: Float
        let deviceDistance: Float
        let userHeight: Float
        let exerciseExperience: ExperienceLevel
        
        enum ExperienceLevel {
            case beginner
            case intermediate
            case advanced
        }
    }
    
    func canExecute(with detectedBody: DetectedBody?) -> Bool {
        // Manual calibration is always available as fallback
        return true
    }
    
    func performCalibration(frames: [CalibrationFrame], exercise: ExerciseType) -> CalibrationData? {
        // In a real implementation, this would use user inputs
        // For now, return conservative defaults
        let baseCalibration = DefaultCalibrationProfiles.getDefault(for: exercise)
        
        return CalibrationData(
            id: UUID(),
            timestamp: Date(),
            exercise: exercise,
            deviceHeight: userInputs?.deviceHeight ?? 0.8,
            deviceAngle: 30.0,
            deviceDistance: userInputs?.deviceDistance ?? 1.5,
            deviceStability: 0.5,
            userHeight: userInputs?.userHeight ?? 1.7,
            armSpan: (userInputs?.userHeight ?? 1.7) * 1.0,
            torsoLength: (userInputs?.userHeight ?? 1.7) * 0.35,
            legLength: (userInputs?.userHeight ?? 1.7) * 0.53,
            angleAdjustments: getConservativeAngleAdjustments(),
            visibilityThresholds: VisibilityThresholds(
                minimumConfidence: 0.65,
                criticalJoints: 0.7,
                supportJoints: 0.6,
                faceJoints: 0.5
            ),
            poseNormalization: baseCalibration.poseNormalization,
            calibrationScore: 60.0,
            confidenceLevel: 0.6,
            frameCount: 0,
            validationRanges: getConservativeValidationRanges()
        )
    }
    
    func getInstructions() -> String {
        "Manual setup mode - We'll guide you through setting up your device position and entering basic information for exercise tracking."
    }
    
    func setUserInputs(_ inputs: ManualCalibrationInputs) {
        self.userInputs = inputs
    }
    
    private func getConservativeAngleAdjustments() -> AngleAdjustments {
        // Very tolerant angles for manual mode
        return AngleAdjustments(
            pushupElbowUp: 160,
            pushupElbowDown: 100,
            pushupBodyAlignment: 30,
            situpTorsoUp: 80,
            situpTorsoDown: 55,
            situpKneeAngle: 80,
            pullupArmExtended: 160,
            pullupArmFlexed: 100,
            pullupBodyVertical: 25
        )
    }
    
    private func getConservativeValidationRanges() -> ValidationRanges {
        return ValidationRanges(
            angleTolerances: ["default": 25.0],
            positionTolerances: ["drift": 0.3],
            movementThresholds: ["speed": 40.0]
        )
    }
}

// MARK: - Calibration Strategy Manager

/// Manages the selection and execution of calibration strategies
class CalibrationStrategyManager: ObservableObject {
    @Published var currentStrategy: CalibrationStrategy?
    @Published var availableStrategies: [CalibrationStrategy] = []
    @Published var strategyInstructions: String = ""
    
    private let exercise: ExerciseType
    private var cancellables = Set<AnyCancellable>()
    
    init(exercise: ExerciseType) {
        self.exercise = exercise
        setupStrategies()
    }
    
    private func setupStrategies() {
        // Initialize all strategies in order of preference
        availableStrategies = [
            FullBodyCalibrationStrategy(),
            PartialBodyCalibrationStrategy(exercise: exercise),
            KeyPointCalibrationStrategy(exercise: exercise),
            ManualCalibrationStrategy()
        ]
    }
    
    /// Select the best available strategy based on detected body
    func selectStrategy(for detectedBody: DetectedBody?) {
        // Try strategies in order of preference
        for strategy in availableStrategies {
            if strategy.canExecute(with: detectedBody) {
                currentStrategy = strategy
                strategyInstructions = strategy.getInstructions()
                return
            }
        }
        
        // Fallback to manual if nothing else works
        currentStrategy = availableStrategies.last
        strategyInstructions = currentStrategy?.getInstructions() ?? ""
    }
    
    /// Try next fallback strategy
    func fallbackToNextStrategy() {
        guard let current = currentStrategy,
              let currentIndex = availableStrategies.firstIndex(where: { $0.strategyName == current.strategyName }),
              currentIndex < availableStrategies.count - 1 else {
            return
        }
        
        currentStrategy = availableStrategies[currentIndex + 1]
        strategyInstructions = currentStrategy?.getInstructions() ?? ""
    }
    
    /// Perform calibration with current strategy
    func performCalibration(frames: [CalibrationFrame]) -> CalibrationData? {
        return currentStrategy?.performCalibration(frames: frames, exercise: exercise)
    }
}
