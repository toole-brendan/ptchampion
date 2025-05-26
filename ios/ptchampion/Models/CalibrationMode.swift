import Foundation

/// Defines different calibration modes for progressive user experience
enum CalibrationMode: String, CaseIterable, Codable {
    case quick = "quick"      // Minimal calibration, use defaults
    case basic = "basic"      // Standard calibration with fewer frames
    case full = "full"        // Complete calibration process
    
    var displayName: String {
        switch self {
        case .quick:
            return "Quick Start"
        case .basic:
            return "Basic Setup"
        case .full:
            return "Full Calibration"
        }
    }
    
    var description: String {
        switch self {
        case .quick:
            return "Start exercising immediately with default settings"
        case .basic:
            return "Quick calibration for good accuracy (30 seconds)"
        case .full:
            return "Complete calibration for best accuracy (60 seconds)"
        }
    }
    
    var requiredFrames: Int {
        switch self {
        case .quick:
            return 0  // No frames needed, use defaults
        case .basic:
            return 30 // Half the frames for quicker setup
        case .full:
            return 60 // Current full calibration
        }
    }
    
    var minimumConfidence: Float {
        switch self {
        case .quick:
            return 0.6  // Lower confidence for quick start
        case .basic:
            return 0.55
        case .full:
            return 0.5
        }
    }
}

/// Default calibration profiles for quick start mode
struct DefaultCalibrationProfiles {
    
    /// Get default calibration data for an exercise
    static func getDefault(for exercise: ExerciseType) -> CalibrationData {
        switch exercise {
        case .pushup:
            return pushupDefault()
        case .situp:
            return situpDefault()
        case .pullup:
            return pullupDefault()
        default:
            return genericDefault(exercise: exercise)
        }
    }
    
    private static func pushupDefault() -> CalibrationData {
        CalibrationData(
            id: UUID(),
            timestamp: Date(),
            exercise: .pushup,
            deviceHeight: 0.3,  // 30cm - typical ground placement
            deviceAngle: 45.0,  // 45° angle for ground view
            deviceDistance: 1.5, // 1.5m typical distance
            deviceStability: 0.8,
            userHeight: 1.7,    // Average height
            armSpan: 1.7,
            torsoLength: 0.6,
            legLength: 0.9,
            angleAdjustments: AngleAdjustments(
                pushupElbowUp: 170,
                pushupElbowDown: 90,
                pushupBodyAlignment: 20,
                situpTorsoUp: 90,
                situpTorsoDown: 45,
                situpKneeAngle: 90,
                pullupArmExtended: 170,
                pullupArmFlexed: 90,
                pullupBodyVertical: 10
            ),
            visibilityThresholds: VisibilityThresholds(
                minimumConfidence: 0.6,
                criticalJoints: 0.65,
                supportJoints: 0.5,
                faceJoints: 0.4
            ),
            poseNormalization: PoseNormalization(
                shoulderWidth: 0.34,
                hipWidth: 0.26,
                armLength: 0.85,
                legLength: 0.9,
                headSize: 0.22
            ),
            calibrationScore: 75.0,  // Default moderate score
            confidenceLevel: 0.75,
            frameCount: 0,
            validationRanges: ValidationRanges(
                angleTolerances: ["pushup_elbow": 15.0, "body_alignment": 25.0],
                positionTolerances: ["horizontal_drift": 0.15, "vertical_drift": 0.15],
                movementThresholds: ["max_speed": 30.0, "min_speed": 2.0]
            )
        )
    }
    
    private static func situpDefault() -> CalibrationData {
        CalibrationData(
            id: UUID(),
            timestamp: Date(),
            exercise: .situp,
            deviceHeight: 0.3,
            deviceAngle: 45.0,
            deviceDistance: 1.8,  // Slightly further for full body view
            deviceStability: 0.8,
            userHeight: 1.7,
            armSpan: 1.7,
            torsoLength: 0.6,
            legLength: 0.9,
            angleAdjustments: AngleAdjustments(
                pushupElbowUp: 170,
                pushupElbowDown: 90,
                pushupBodyAlignment: 15,
                situpTorsoUp: 90,
                situpTorsoDown: 45,
                situpKneeAngle: 90,
                pullupArmExtended: 170,
                pullupArmFlexed: 90,
                pullupBodyVertical: 10
            ),
            visibilityThresholds: VisibilityThresholds(
                minimumConfidence: 0.6,
                criticalJoints: 0.65,
                supportJoints: 0.5,
                faceJoints: 0.4
            ),
            poseNormalization: PoseNormalization(
                shoulderWidth: 0.34,
                hipWidth: 0.26,
                armLength: 0.85,
                legLength: 0.9,
                headSize: 0.22
            ),
            calibrationScore: 75.0,
            confidenceLevel: 0.75,
            frameCount: 0,
            validationRanges: ValidationRanges(
                angleTolerances: ["situp_torso": 20.0, "knee_angle": 15.0],
                positionTolerances: ["horizontal_drift": 0.2, "vertical_drift": 0.15],
                movementThresholds: ["max_speed": 25.0, "min_speed": 3.0]
            )
        )
    }
    
    private static func pullupDefault() -> CalibrationData {
        CalibrationData(
            id: UUID(),
            timestamp: Date(),
            exercise: .pullup,
            deviceHeight: 1.0,   // Elevated for pull-up bar view
            deviceAngle: 15.0,   // Slight upward angle
            deviceDistance: 2.0, // Further back for full view
            deviceStability: 0.8,
            userHeight: 1.7,
            armSpan: 1.7,
            torsoLength: 0.6,
            legLength: 0.9,
            angleAdjustments: AngleAdjustments(
                pushupElbowUp: 170,
                pushupElbowDown: 90,
                pushupBodyAlignment: 15,
                situpTorsoUp: 90,
                situpTorsoDown: 45,
                situpKneeAngle: 90,
                pullupArmExtended: 170,
                pullupArmFlexed: 90,
                pullupBodyVertical: 15  // More tolerance for swing
            ),
            visibilityThresholds: VisibilityThresholds(
                minimumConfidence: 0.6,
                criticalJoints: 0.65,
                supportJoints: 0.5,
                faceJoints: 0.4
            ),
            poseNormalization: PoseNormalization(
                shoulderWidth: 0.34,
                hipWidth: 0.26,
                armLength: 0.85,
                legLength: 0.9,
                headSize: 0.22
            ),
            calibrationScore: 75.0,
            confidenceLevel: 0.75,
            frameCount: 0,
            validationRanges: ValidationRanges(
                angleTolerances: ["pullup_arm": 15.0, "body_vertical": 20.0],
                positionTolerances: ["horizontal_drift": 0.25, "vertical_drift": 0.1],
                movementThresholds: ["max_speed": 35.0, "min_speed": 2.0]
            )
        )
    }
    
    private static func genericDefault(exercise: ExerciseType) -> CalibrationData {
        CalibrationData(
            id: UUID(),
            timestamp: Date(),
            exercise: exercise,
            deviceHeight: 0.8,
            deviceAngle: 30.0,
            deviceDistance: 1.5,
            deviceStability: 0.8,
            userHeight: 1.7,
            armSpan: 1.7,
            torsoLength: 0.6,
            legLength: 0.9,
            angleAdjustments: AngleAdjustments(
                pushupElbowUp: 170,
                pushupElbowDown: 90,
                pushupBodyAlignment: 20,
                situpTorsoUp: 90,
                situpTorsoDown: 45,
                situpKneeAngle: 90,
                pullupArmExtended: 170,
                pullupArmFlexed: 90,
                pullupBodyVertical: 15
            ),
            visibilityThresholds: VisibilityThresholds(
                minimumConfidence: 0.6,
                criticalJoints: 0.65,
                supportJoints: 0.5,
                faceJoints: 0.4
            ),
            poseNormalization: PoseNormalization(
                shoulderWidth: 0.34,
                hipWidth: 0.26,
                armLength: 0.85,
                legLength: 0.9,
                headSize: 0.22
            ),
            calibrationScore: 70.0,
            confidenceLevel: 0.7,
            frameCount: 0,
            validationRanges: ValidationRanges(
                angleTolerances: [:],
                positionTolerances: ["horizontal_drift": 0.2, "vertical_drift": 0.2],
                movementThresholds: ["max_speed": 30.0, "min_speed": 2.0]
            )
        )
    }
}

/// Tracks calibration progress and prompts
struct CalibrationProgress: Codable {
    let exercise: ExerciseType
    let mode: CalibrationMode
    let completedReps: Int
    let lastPromptDate: Date?
    let hasCompletedFullCalibration: Bool
    
    /// Should prompt for calibration upgrade
    func shouldPromptForUpgrade() -> Bool {
        guard !hasCompletedFullCalibration else { return false }
        
        // Prompt after 10 reps in quick mode, 25 reps in basic mode
        switch mode {
        case .quick:
            return completedReps >= 10
        case .basic:
            return completedReps >= 25
        case .full:
            return false
        }
    }
}
