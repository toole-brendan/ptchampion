import Foundation
import CoreGraphics
import CoreMotion
import Vision

// MARK: - Calibration Data Models

/// Main calibration data structure containing all device and user-specific adjustments
struct CalibrationData: Codable, Identifiable, Hashable {
    let id: UUID
    let timestamp: Date
    let exercise: ExerciseType
    
    // Device positioning data
    let deviceHeight: Float // meters from ground
    let deviceAngle: Float // degrees from vertical
    let deviceDistance: Float // meters from user
    let deviceStability: Float // 0-1 stability score
    
    // User measurements (normalized)
    let userHeight: Float // estimated height in meters
    let armSpan: Float // meters
    let torsoLength: Float // meters
    let legLength: Float // meters
    
    // Exercise-specific calibration adjustments
    let angleAdjustments: AngleAdjustments
    let visibilityThresholds: VisibilityThresholds
    let poseNormalization: PoseNormalization
    
    // Quality metrics
    let calibrationScore: Float // 0-100
    let confidenceLevel: Float // 0-1
    let frameCount: Int // number of frames analyzed
    
    // Validation ranges for pose detection
    let validationRanges: ValidationRanges
    
    enum CodingKeys: String, CodingKey {
        case id, timestamp, exercise
        case deviceHeight = "device_height"
        case deviceAngle = "device_angle"
        case deviceDistance = "device_distance"
        case deviceStability = "device_stability"
        case userHeight = "user_height"
        case armSpan = "arm_span"
        case torsoLength = "torso_length"
        case legLength = "leg_length"
        case angleAdjustments = "angle_adjustments"
        case visibilityThresholds = "visibility_thresholds"
        case poseNormalization = "pose_normalization"
        case calibrationScore = "calibration_score"
        case confidenceLevel = "confidence_level"
        case frameCount = "frame_count"
        case validationRanges = "validation_ranges"
    }
}

/// Exercise-specific angle adjustments based on camera position and user anatomy
struct AngleAdjustments: Codable, Hashable {
    // Pushup angles
    let pushupElbowUp: Float      // Target angle when arms extended
    let pushupElbowDown: Float    // Target angle when arms flexed
    let pushupBodyAlignment: Float // Acceptable body deviation
    
    // Situp angles
    let situpTorsoUp: Float       // Target angle when sitting up
    let situpTorsoDown: Float     // Target angle when lying down
    let situpKneeAngle: Float     // Required knee angle
    
    // Pullup angles
    let pullupArmExtended: Float  // Target angle when hanging
    let pullupArmFlexed: Float    // Target angle when pulled up
    let pullupBodyVertical: Float // Acceptable swing tolerance
    
    enum CodingKeys: String, CodingKey {
        case pushupElbowUp = "pushup_elbow_up"
        case pushupElbowDown = "pushup_elbow_down"
        case pushupBodyAlignment = "pushup_body_alignment"
        case situpTorsoUp = "situp_torso_up"
        case situpTorsoDown = "situp_torso_down"
        case situpKneeAngle = "situp_knee_angle"
        case pullupArmExtended = "pullup_arm_extended"
        case pullupArmFlexed = "pullup_arm_flexed"
        case pullupBodyVertical = "pullup_body_vertical"
    }
    
    /// Get the appropriate angle adjustment for a specific metric
    func getAdjustment(for exercise: ExerciseType, metric: String) -> Float? {
        switch (exercise, metric) {
        case (.pushup, "elbow_up"): return pushupElbowUp
        case (.pushup, "elbow_down"): return pushupElbowDown
        case (.pushup, "body_alignment"): return pushupBodyAlignment
        case (.situp, "torso_up"): return situpTorsoUp
        case (.situp, "torso_down"): return situpTorsoDown
        case (.situp, "knee_angle"): return situpKneeAngle
        case (.pullup, "arm_extended"): return pullupArmExtended
        case (.pullup, "arm_flexed"): return pullupArmFlexed
        case (.pullup, "body_vertical"): return pullupBodyVertical
        default: return nil
        }
    }
}

/// Confidence thresholds for pose landmark visibility
struct VisibilityThresholds: Codable, Hashable {
    let minimumConfidence: Float // Overall minimum confidence
    let criticalJoints: Float    // Confidence for key joints (shoulders, elbows, etc.)
    let supportJoints: Float     // Confidence for supporting joints
    let faceJoints: Float        // Confidence for face landmarks
    
    enum CodingKeys: String, CodingKey {
        case minimumConfidence = "minimum_confidence"
        case criticalJoints = "critical_joints"
        case supportJoints = "support_joints"
        case faceJoints = "face_joints"
    }
}

/// Pose normalization factors based on user measurements
struct PoseNormalization: Codable, Hashable {
    let shoulderWidth: Float     // Normalized shoulder width
    let hipWidth: Float          // Normalized hip width
    let armLength: Float         // Normalized arm length
    let legLength: Float         // Normalized leg length
    let headSize: Float          // Normalized head size for distance calculation
    
    enum CodingKeys: String, CodingKey {
        case shoulderWidth = "shoulder_width"
        case hipWidth = "hip_width"
        case armLength = "arm_length"
        case legLength = "leg_length"
        case headSize = "head_size"
    }
}

/// Validation ranges for pose measurements
struct ValidationRanges: Codable, Hashable {
    let angleTolerances: [String: Float] // Acceptable angle deviations
    let positionTolerances: [String: Float] // Acceptable position deviations
    let movementThresholds: [String: Float] // Movement speed thresholds
    
    enum CodingKeys: String, CodingKey {
        case angleTolerances = "angle_tolerances"
        case positionTolerances = "position_tolerances"
        case movementThresholds = "movement_thresholds"
    }
}

// MARK: - Calibration Frame Data

/// Single frame data collected during calibration
struct CalibrationFrame: Hashable {
    let timestamp: TimeInterval
    let poseData: DetectedBody
    let deviceMotion: DeviceMotionData?
    let frameQuality: FrameQuality
    
    /// Quality assessment for the frame
    struct FrameQuality: Hashable {
        let overallConfidence: Float
        let jointVisibility: [String: Float] // Using String keys for Hashable conformance
        let bodyCompleteness: Float // 0-1, how much of body is visible
        let stability: Float // 0-1, how stable the pose is
        let lighting: Float // 0-1, lighting quality assessment
        
        init(overallConfidence: Float,
             jointVisibility: [VNHumanBodyPoseObservation.JointName: Float],
             bodyCompleteness: Float,
             stability: Float,
             lighting: Float) {
            self.overallConfidence = overallConfidence
            // Convert JointName to String for storage
            self.jointVisibility = Dictionary(uniqueKeysWithValues: 
                jointVisibility.map { (key, value) in (key.rawValue.rawValue, value) })
            self.bodyCompleteness = bodyCompleteness
            self.stability = stability
            self.lighting = lighting
        }
    }
}

/// Device motion data captured during calibration
struct DeviceMotionData: Hashable {
    let timestamp: TimeInterval
    let attitude: AttitudeData
    let rotationRate: RotationRateData
    let gravity: GravityVector
    let userAcceleration: AccelerationVector
    
    struct AttitudeData: Hashable {
        let roll: Double
        let pitch: Double
        let yaw: Double
    }
    
    struct RotationRateData: Hashable {
        let x: Double
        let y: Double
        let z: Double
    }
    
    struct GravityVector: Hashable {
        let x: Double
        let y: Double
        let z: Double
    }
    
    struct AccelerationVector: Hashable {
        let x: Double
        let y: Double
        let z: Double
    }
    
    init(from motion: CMDeviceMotion) {
        self.timestamp = motion.timestamp
        self.attitude = AttitudeData(
            roll: motion.attitude.roll,
            pitch: motion.attitude.pitch,
            yaw: motion.attitude.yaw
        )
        self.rotationRate = RotationRateData(
            x: motion.rotationRate.x,
            y: motion.rotationRate.y,
            z: motion.rotationRate.z
        )
        self.gravity = GravityVector(
            x: motion.gravity.x,
            y: motion.gravity.y,
            z: motion.gravity.z
        )
        self.userAcceleration = AccelerationVector(
            x: motion.userAcceleration.x,
            y: motion.userAcceleration.y,
            z: motion.userAcceleration.z
        )
    }
}

// MARK: - Calibration Status and Quality

/// Overall calibration quality assessment
enum CalibrationQuality: String, CaseIterable {
    case excellent = "excellent"    // 90-100 score
    case good = "good"             // 80-89 score
    case acceptable = "acceptable" // 70-79 score
    case poor = "poor"             // 60-69 score
    case invalid = "invalid"       // < 60 score
    
    var description: String {
        switch self {
        case .excellent:
            return "Excellent calibration - optimal accuracy expected"
        case .good:
            return "Good calibration - high accuracy expected"
        case .acceptable:
            return "Acceptable calibration - moderate accuracy expected"
        case .poor:
            return "Poor calibration - reduced accuracy possible"
        case .invalid:
            return "Invalid calibration - recalibration recommended"
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .acceptable: return "orange"
        case .poor: return "red"
        case .invalid: return "red"
        }
    }
}

/// Framing assessment for user positioning
enum FramingStatus: String {
    case unknown = "unknown"
    case tooClose = "too_close"
    case tooFar = "too_far"
    case tooLeft = "too_left"
    case tooRight = "too_right"
    case tooHigh = "too_high"
    case tooLow = "too_low"
    case acceptable = "acceptable"
    case optimal = "optimal"
    
    var isAcceptable: Bool {
        return self == .acceptable || self == .optimal
    }
    
    var instruction: String {
        switch self {
        case .unknown: return "Position yourself in front of the camera"
        case .tooClose: return "Step back from the device"
        case .tooFar: return "Move closer to the device"
        case .tooLeft: return "Move to the right"
        case .tooRight: return "Move to the left"
        case .tooHigh: return "Lower your position or raise the device"
        case .tooLow: return "Raise your position or lower the device"
        case .acceptable: return "Good positioning - ready to start"
        case .optimal: return "Perfect positioning!"
        }
    }
}

/// Specific calibration suggestions for improvement
struct CalibrationSuggestion: Identifiable, Hashable {
    let id = UUID()
    let type: SuggestionType
    let priority: Priority
    let message: String
    let actionRequired: Bool
    
    enum SuggestionType: String, CaseIterable {
        case devicePosition = "device_position"
        case userPosition = "user_position"
        case lighting = "lighting"
        case stability = "stability"
        case bodyVisibility = "body_visibility"
        case exerciseSetup = "exercise_setup"
    }
    
    enum Priority: String, CaseIterable {
        case critical = "critical"
        case important = "important"
        case minor = "minor"
    }
}

// MARK: - Target Framing for Exercises

/// Target framing requirements for each exercise type
struct TargetFraming {
    let exercise: ExerciseType
    let bodyParts: [VNHumanBodyPoseObservation.JointName] // Required visible body parts
    let optimalDistance: Float // Optimal distance from camera (normalized)
    let acceptableDistanceRange: ClosedRange<Float>
    let verticalCenterRange: ClosedRange<Float> // Where body center should be vertically
    let horizontalCenterRange: ClosedRange<Float> // Where body center should be horizontally
    let minBodyCoverage: Float // Minimum percentage of body that should be visible
    
    static func getTargetFraming(for exercise: ExerciseType) -> TargetFraming {
        switch exercise {
        case .pushup:
            return TargetFraming(
                exercise: exercise,
                bodyParts: [
                    VNHumanBodyPoseObservation.JointName.leftShoulder, 
                    VNHumanBodyPoseObservation.JointName.rightShoulder, 
                    VNHumanBodyPoseObservation.JointName.leftElbow, 
                    VNHumanBodyPoseObservation.JointName.rightElbow, 
                    VNHumanBodyPoseObservation.JointName.leftWrist, 
                    VNHumanBodyPoseObservation.JointName.rightWrist, 
                    VNHumanBodyPoseObservation.JointName.leftHip, 
                    VNHumanBodyPoseObservation.JointName.rightHip, 
                    VNHumanBodyPoseObservation.JointName.leftAnkle, 
                    VNHumanBodyPoseObservation.JointName.rightAnkle
                ],
                optimalDistance: 1.5,              // Changed from 0.7
                acceptableDistanceRange: 1.2...2.0, // Changed from 0.5...0.9
                verticalCenterRange: 0.4...0.6,     // Keep the same
                horizontalCenterRange: 0.2...0.8,   // Changed from 0.3...0.7
                minBodyCoverage: 0.7                // Changed from 0.8
            )
            
        case .situp:
            return TargetFraming(
                exercise: exercise,
                bodyParts: [
                    VNHumanBodyPoseObservation.JointName.leftShoulder, 
                    VNHumanBodyPoseObservation.JointName.rightShoulder, 
                    VNHumanBodyPoseObservation.JointName.leftElbow, 
                    VNHumanBodyPoseObservation.JointName.rightElbow,
                    VNHumanBodyPoseObservation.JointName.leftHip, 
                    VNHumanBodyPoseObservation.JointName.rightHip, 
                    VNHumanBodyPoseObservation.JointName.leftKnee, 
                    VNHumanBodyPoseObservation.JointName.rightKnee, 
                    VNHumanBodyPoseObservation.JointName.nose
                ],
                optimalDistance: 1.4,               // Changed from 0.6
                acceptableDistanceRange: 1.1...1.9, // Changed from 0.4...0.8
                verticalCenterRange: 0.25...0.75,   // Changed from 0.3...0.7
                horizontalCenterRange: 0.2...0.8,   // Changed from 0.3...0.7
                minBodyCoverage: 0.65               // Changed from 0.75
            )
            
        case .pullup:
            return TargetFraming(
                exercise: exercise,
                bodyParts: [
                    VNHumanBodyPoseObservation.JointName.leftShoulder, 
                    VNHumanBodyPoseObservation.JointName.rightShoulder, 
                    VNHumanBodyPoseObservation.JointName.leftElbow, 
                    VNHumanBodyPoseObservation.JointName.rightElbow,
                    VNHumanBodyPoseObservation.JointName.leftWrist, 
                    VNHumanBodyPoseObservation.JointName.rightWrist, 
                    VNHumanBodyPoseObservation.JointName.leftHip, 
                    VNHumanBodyPoseObservation.JointName.rightHip, 
                    VNHumanBodyPoseObservation.JointName.leftKnee, 
                    VNHumanBodyPoseObservation.JointName.rightKnee, 
                    VNHumanBodyPoseObservation.JointName.nose
                ],
                optimalDistance: 1.6,               // Changed from 0.8
                acceptableDistanceRange: 1.3...2.2, // Changed from 0.6...1.0
                verticalCenterRange: 0.15...0.85,   // Changed from 0.2...0.8
                horizontalCenterRange: 0.2...0.8,   // Changed from 0.3...0.7
                minBodyCoverage: 0.75               // Changed from 0.85
            )
            
        case .run, .unknown:
            // Running doesn't use pose detection calibration
            return TargetFraming(
                exercise: exercise,
                bodyParts: [],
                optimalDistance: 1.0,
                acceptableDistanceRange: 0.5...1.0,
                verticalCenterRange: 0.0...1.0,
                horizontalCenterRange: 0.0...1.0,
                minBodyCoverage: 0.0
            )
        }
    }
}
