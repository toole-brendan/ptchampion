// ios/ptchampion/Grading/APFTRepValidator.swift

import Foundation
import Vision
import CoreGraphics
import simd

/// APFT-compliant rep validator that implements military fitness test standards
/// for pushups, pullups, and situps using MediaPipe Blaze pose landmarks
class APFTRepValidator: ObservableObject {
    
    // MARK: - Landmark Constants (MediaPipe Blaze indices)
    private enum LandmarkIndex: Int {
        case nose = 0
        case leftEyeInner = 1, leftEye = 2, leftEyeOuter = 3
        case rightEyeInner = 4, rightEye = 5, rightEyeOuter = 6
        case leftEar = 7, rightEar = 8
        case mouthLeft = 9, mouthRight = 10
        case leftShoulder = 11, rightShoulder = 12
        case leftElbow = 13, rightElbow = 14
        case leftWrist = 15, rightWrist = 16
        case leftHip = 23, rightHip = 24
        case leftKnee = 25, rightKnee = 26
        case leftAnkle = 27, rightAnkle = 28
        case leftHeel = 29, rightHeel = 30
        case leftToe = 31, rightToe = 32
    }
    
    // MARK: - Exercise Phases
    enum PushupPhase: String {
        case up = "up"
        case descending = "descending"
        case ascending = "ascending"
        case invalid = "invalid"
    }
    
    enum PullupPhase: String {
        case down = "down"
        case pulling = "pulling"
        case lowering = "lowering"
        case invalid = "invalid"
    }
    
    enum SitupPhase: String {
        case down = "down"
        case rising = "rising"
        case lowering = "lowering"
        case invalid = "invalid"
    }
    
    // MARK: - Exercise State
    struct ExerciseState {
        var phase: String
        var repCount: Int
        var inValidRep: Bool
        var formIssues: [String]
        var additionalData: [String: Any]
        
        init(phase: String) {
            self.phase = phase
            self.repCount = 0
            self.inValidRep = false
            self.formIssues = []
            self.additionalData = [:]
        }
    }
    
    // MARK: - State Tracking
    @Published private var pushupState = ExerciseState(phase: PushupPhase.up.rawValue)
    @Published private var pullupState = ExerciseState(phase: PullupPhase.down.rawValue)
    @Published private var situpState = ExerciseState(phase: SitupPhase.down.rawValue)
    
    // MARK: - APFT Standards (adjustable for different fitness levels)
    struct APFTStandards {
        // Pushup standards
        static let pushupArmExtensionAngle: Float = 160.0  // Nearly straight arms
        static let pushupArmParallelAngle: Float = 95.0    // Upper arms parallel to ground
        static let pushupBodyAlignmentTolerance: Float = 15.0  // Degrees from straight
        static let pushupMinDescentThreshold: Float = 0.02  // Minimum descent distance
        static let pushupPositionTolerance: Float = 0.01   // Return to start position tolerance
        
        // Pullup standards
        static let pullupArmExtensionAngle: Float = 160.0  // Dead hang position
        static let pullupArmFlexionAngle: Float = 120.0    // Arms significantly bent
        static let pullupBodyAlignmentTolerance: Float = 20.0  // More tolerance for hanging
        static let pullupChinClearance: Float = 0.02       // Chin must clearly pass over bar
        static let pullupChinBelowBar: Float = 0.05        // Chin clearly below bar
        static let pullupMaxSwing: Float = 0.1             // Maximum horizontal drift
        
        // Situp standards
        static let situpKneeAngleMin: Float = 80.0         // Minimum knee angle
        static let situpKneeAngleMax: Float = 100.0        // Maximum knee angle
        static let situpTorsoHorizontalMax: Float = 15.0   // Nearly horizontal start
        static let situpTorsoVerticalMin: Float = 75.0     // Near vertical top position
    }
    
    // MARK: - Public Interface
    var pushupRepCount: Int { pushupState.repCount }
    var pullupRepCount: Int { pullupState.repCount }
    var situpRepCount: Int { situpState.repCount }
    
    var pushupPhase: String { pushupState.phase }
    var pullupPhase: String { pullupState.phase }
    var situpPhase: String { situpState.phase }
    
    var pushupFormIssues: [String] { pushupState.formIssues }
    var pullupFormIssues: [String] { pullupState.formIssues }
    var situpFormIssues: [String] { situpState.formIssues }
    
    // MARK: - Angle Calculation
    private func calculateAngle(point1: CGPoint, vertex: CGPoint, point3: CGPoint) -> Float {
        let vector1 = simd_float2(Float(point1.x - vertex.x), Float(point1.y - vertex.y))
        let vector2 = simd_float2(Float(point3.x - vertex.x), Float(point3.y - vertex.y))
        
        let dotProduct = simd_dot(vector1, vector2)
        let magnitude1 = simd_length(vector1)
        let magnitude2 = simd_length(vector2)
        
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0 }
        
        let cosAngle = simd_clamp(dotProduct / (magnitude1 * magnitude2), -1.0, 1.0)
        return acos(cosAngle) * 180.0 / Float.pi
    }
    
    private func calculateDistance(point1: CGPoint, point2: CGPoint) -> Float {
        let dx = Float(point1.x - point2.x)
        let dy = Float(point1.y - point2.y)
        return sqrt(dx * dx + dy * dy)
    }
    
    // MARK: - Body Alignment
    private func getBodyAlignmentAngle(body: DetectedBody) -> Float? {
        guard let leftShoulder = body.point(.leftShoulder),
              let rightShoulder = body.point(.rightShoulder),
              let leftHip = body.point(.leftHip),
              let rightHip = body.point(.rightHip),
              let leftAnkle = body.point(.leftAnkle),
              let rightAnkle = body.point(.rightAnkle) else {
            return nil
        }
        
        // Calculate midpoints
        let shoulderMid = CGPoint(
            x: (leftShoulder.location.x + rightShoulder.location.x) / 2,
            y: (leftShoulder.location.y + rightShoulder.location.y) / 2
        )
        let hipMid = CGPoint(
            x: (leftHip.location.x + rightHip.location.x) / 2,
            y: (leftHip.location.y + rightHip.location.y) / 2
        )
        let ankleMid = CGPoint(
            x: (leftAnkle.location.x + rightAnkle.location.x) / 2,
            y: (leftAnkle.location.y + rightAnkle.location.y) / 2
        )
        
        // Calculate angle from vertical (shoulder to ankle line)
        let bodyVector = simd_float2(Float(ankleMid.x - shoulderMid.x), Float(ankleMid.y - shoulderMid.y))
        let verticalVector = simd_float2(0, 1)  // Pointing down
        
        let dotProduct = simd_dot(bodyVector, verticalVector)
        let bodyMagnitude = simd_length(bodyVector)
        
        guard bodyMagnitude > 0 else { return 0 }
        
        let cosAngle = simd_clamp(dotProduct / bodyMagnitude, -1.0, 1.0)
        return acos(cosAngle) * 180.0 / Float.pi
    }
    
    // MARK: - Pushup Validation
    func validatePushup(body: DetectedBody) -> Bool {
        guard let leftShoulder = body.point(.leftShoulder),
              let rightShoulder = body.point(.rightShoulder),
              let leftElbow = body.point(.leftElbow),
              let rightElbow = body.point(.rightElbow),
              let leftWrist = body.point(.leftWrist),
              let rightWrist = body.point(.rightWrist) else {
            pushupState.formIssues = ["Cannot detect all required body parts"]
            return false
        }
        
        // Clear previous form issues
        pushupState.formIssues = []
        
        // Calculate arm angles (shoulder-elbow-wrist)
        let leftArmAngle = calculateAngle(point1: leftShoulder.location, vertex: leftElbow.location, point3: leftWrist.location)
        let rightArmAngle = calculateAngle(point1: rightShoulder.location, vertex: rightElbow.location, point3: rightWrist.location)
        let avgArmAngle = (leftArmAngle + rightArmAngle) / 2
        
        // Check body alignment
        guard let bodyAlignment = getBodyAlignmentAngle(body: body) else {
            pushupState.formIssues.append("Cannot calculate body alignment")
            return false
        }
        
        let isBodyStraight = bodyAlignment <= APFTStandards.pushupBodyAlignmentTolerance
        if !isBodyStraight {
            pushupState.formIssues.append("Keep body straight")
        }
        
        // Get shoulder height for tracking vertical movement
        let shoulderMidY = (leftShoulder.location.y + rightShoulder.location.y) / 2
        
        // State machine logic
        switch PushupPhase(rawValue: pushupState.phase) ?? .invalid {
        case .up:
            // Check if starting position is valid (arms extended, body straight)
            let armsExtended = avgArmAngle > APFTStandards.pushupArmExtensionAngle
            
            if armsExtended && isBodyStraight {
                // Ready to start descent
                pushupState.additionalData["startShoulderHeight"] = shoulderMidY
                pushupState.phase = PushupPhase.descending.rawValue
                pushupState.inValidRep = true
            } else {
                if !armsExtended { pushupState.formIssues.append("Extend arms fully") }
            }
            
        case .descending:
            // Check if upper arms are parallel to ground
            let armsParallel = avgArmAngle <= APFTStandards.pushupArmParallelAngle
            let startHeight = pushupState.additionalData["startShoulderHeight"] as? CGFloat ?? shoulderMidY
            let descentDistance = shoulderMidY - startHeight
            let sufficientDescent = Float(descentDistance) > APFTStandards.pushupMinDescentThreshold
            
            if armsParallel && isBodyStraight && sufficientDescent {
                pushupState.phase = PushupPhase.ascending.rawValue
                pushupState.additionalData["bottomReached"] = true
            } else {
                if !armsParallel { pushupState.formIssues.append("Lower until upper arms are parallel to ground") }
                if !sufficientDescent { pushupState.formIssues.append("Go lower") }
                if !isBodyStraight {
                    // Body alignment lost - invalidate rep
                    pushupState.phase = PushupPhase.up.rawValue
                    pushupState.inValidRep = false
                }
            }
            
        case .ascending:
            // Check return to full extension
            let armsExtended = avgArmAngle > APFTStandards.pushupArmExtensionAngle
            let startHeight = pushupState.additionalData["startShoulderHeight"] as? CGFloat ?? shoulderMidY
            let returnedToStart = Float(abs(shoulderMidY - startHeight)) < APFTStandards.pushupPositionTolerance
            let bottomReached = pushupState.additionalData["bottomReached"] as? Bool ?? false
            
            if armsExtended && isBodyStraight && returnedToStart && bottomReached {
                // Valid rep completed
                pushupState.repCount += 1
                pushupState.phase = PushupPhase.up.rawValue
                pushupState.inValidRep = false
                pushupState.additionalData.removeValue(forKey: "bottomReached")
                pushupState.additionalData.removeValue(forKey: "startShoulderHeight")
                return true
            } else {
                if !armsExtended { pushupState.formIssues.append("Extend arms fully") }
                if !isBodyStraight {
                    // Body alignment lost - invalidate rep
                    pushupState.phase = PushupPhase.up.rawValue
                    pushupState.inValidRep = false
                    pushupState.additionalData.removeValue(forKey: "bottomReached")
                    pushupState.additionalData.removeValue(forKey: "startShoulderHeight")
                }
            }
            
        case .invalid:
            pushupState.phase = PushupPhase.up.rawValue
        }
        
        return false
    }
    
    // MARK: - Pullup Validation
    func validatePullup(body: DetectedBody, barHeightY: Float = 0.2) -> Bool {
        guard let leftShoulder = body.point(.leftShoulder),
              let rightShoulder = body.point(.rightShoulder),
              let leftElbow = body.point(.leftElbow),
              let rightElbow = body.point(.rightElbow),
              let leftWrist = body.point(.leftWrist),
              let rightWrist = body.point(.rightWrist),
              let nose = body.point(.nose) else {
            pullupState.formIssues = ["Cannot detect all required body parts"]
            return false
        }
        
        // Clear previous form issues
        pullupState.formIssues = []
        
        // Calculate arm angles and extension
        let leftArmAngle = calculateAngle(point1: leftShoulder.location, vertex: leftElbow.location, point3: leftWrist.location)
        let rightArmAngle = calculateAngle(point1: rightShoulder.location, vertex: rightElbow.location, point3: rightWrist.location)
        let avgArmAngle = (leftArmAngle + rightArmAngle) / 2
        
        // Check body alignment and stability
        guard let bodyAlignment = getBodyAlignmentAngle(body: body) else {
            pullupState.formIssues.append("Cannot calculate body alignment")
            return false
        }
        
        let isStable = bodyAlignment <= APFTStandards.pullupBodyAlignmentTolerance
        if !isStable {
            pullupState.formIssues.append("Minimize body swing")
        }
        
        // Chin position (using nose as proxy)
        let chinY = Float(nose.location.y)
        let shoulderMidX = (leftShoulder.location.x + rightShoulder.location.x) / 2
        
        // State machine logic
        switch PullupPhase(rawValue: pullupState.phase) ?? .invalid {
        case .down:
            // Check if in dead hang (arms extended, chin below bar)
            let armsExtended = avgArmAngle > APFTStandards.pullupArmExtensionAngle
            let chinBelowBar = chinY > barHeightY + APFTStandards.pullupChinBelowBar
            
            if armsExtended && chinBelowBar && isStable {
                pullupState.phase = PullupPhase.pulling.rawValue
                pullupState.inValidRep = true
                pullupState.additionalData["startPositionX"] = shoulderMidX
            } else {
                if !armsExtended { pullupState.formIssues.append("Extend arms fully for dead hang") }
                if !chinBelowBar { pullupState.formIssues.append("Lower to complete dead hang") }
            }
            
        case .pulling:
            // Check if chin passes over bar
            let chinOverBar = chinY < barHeightY - APFTStandards.pullupChinClearance
            let armsFlexed = avgArmAngle < APFTStandards.pullupArmFlexionAngle
            
            // Check for excessive swing
            let startPositionX = pullupState.additionalData["startPositionX"] as? CGFloat ?? shoulderMidX
            let horizontalDrift = abs(shoulderMidX - startPositionX)
            let excessiveSwing = Float(horizontalDrift) > APFTStandards.pullupMaxSwing
            
            if chinOverBar && armsFlexed && isStable && !excessiveSwing {
                pullupState.phase = PullupPhase.lowering.rawValue
                pullupState.additionalData["topReached"] = true
            } else {
                if !chinOverBar { pullupState.formIssues.append("Pull chin over bar") }
                if !armsFlexed { pullupState.formIssues.append("Pull higher") }
                if excessiveSwing { pullupState.formIssues.append("Minimize swinging") }
                if excessiveSwing || !isStable {
                    // Invalid due to swinging or instability
                    pullupState.phase = PullupPhase.down.rawValue
                    pullupState.inValidRep = false
                    pullupState.additionalData.removeValue(forKey: "startPositionX")
                }
            }
            
        case .lowering:
            // Check return to dead hang
            let armsExtended = avgArmAngle > APFTStandards.pullupArmExtensionAngle
            let chinBelowBar = chinY > barHeightY + APFTStandards.pullupChinBelowBar
            let topReached = pullupState.additionalData["topReached"] as? Bool ?? false
            
            if armsExtended && chinBelowBar && topReached {
                // Valid rep completed
                pullupState.repCount += 1
                pullupState.phase = PullupPhase.down.rawValue
                pullupState.inValidRep = false
                pullupState.additionalData.removeValue(forKey: "topReached")
                pullupState.additionalData.removeValue(forKey: "startPositionX")
                return true
            } else {
                if !armsExtended { pullupState.formIssues.append("Lower to complete dead hang") }
                if !chinBelowBar { pullupState.formIssues.append("Lower chin below bar") }
            }
            
        case .invalid:
            pullupState.phase = PullupPhase.down.rawValue
        }
        
        return false
    }
    
    // MARK: - Situp Validation
    func validateSitup(body: DetectedBody) -> Bool {
        guard let leftShoulder = body.point(.leftShoulder),
              let rightShoulder = body.point(.rightShoulder),
              let leftHip = body.point(.leftHip),
              let rightHip = body.point(.rightHip),
              let leftKnee = body.point(.leftKnee),
              let rightKnee = body.point(.rightKnee),
              let leftAnkle = body.point(.leftAnkle),
              let rightAnkle = body.point(.rightAnkle) else {
            situpState.formIssues = ["Cannot detect all required body parts"]
            return false
        }
        
        // Clear previous form issues
        situpState.formIssues = []
        
        // Calculate knee angles (hip-knee-ankle) - should be around 90 degrees
        let leftKneeAngle = calculateAngle(point1: leftHip.location, vertex: leftKnee.location, point3: leftAnkle.location)
        let rightKneeAngle = calculateAngle(point1: rightHip.location, vertex: rightKnee.location, point3: rightAnkle.location)
        let avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2
        
        // Check if knees are at proper 90-degree angle
        let kneesProper = avgKneeAngle >= APFTStandards.situpKneeAngleMin && avgKneeAngle <= APFTStandards.situpKneeAngleMax
        if !kneesProper {
            situpState.formIssues.append("Keep knees at 90-degree angle")
        }
        
        // Calculate torso angle (from horizontal)
        let shoulderMid = CGPoint(
            x: (leftShoulder.location.x + rightShoulder.location.x) / 2,
            y: (leftShoulder.location.y + rightShoulder.location.y) / 2
        )
        let hipMid = CGPoint(
            x: (leftHip.location.x + rightHip.location.x) / 2,
            y: (leftHip.location.y + rightHip.location.y) / 2
        )
        
        // Torso vector (from hips to shoulders)
        let torsoVector = simd_float2(Float(shoulderMid.x - hipMid.x), Float(shoulderMid.y - hipMid.y))
        let horizontalVector = simd_float2(1, 0)  // Horizontal reference
        
        let dotProduct = simd_dot(torsoVector, horizontalVector)
        let torsoMagnitude = simd_length(torsoVector)
        
        guard torsoMagnitude > 0 else {
            situpState.formIssues.append("Cannot calculate torso angle")
            return false
        }
        
        let cosAngle = simd_clamp(abs(dotProduct) / torsoMagnitude, 0.0, 1.0)
        let torsoAngle = acos(cosAngle) * 180.0 / Float.pi
        
        // State machine logic
        switch SitupPhase(rawValue: situpState.phase) ?? .invalid {
        case .down:
            // Check if in starting position (shoulders on ground, knees at 90°)
            let shouldersDown = torsoAngle < APFTStandards.situpTorsoHorizontalMax
            
            if shouldersDown && kneesProper {
                situpState.phase = SitupPhase.rising.rawValue
                situpState.inValidRep = true
            } else {
                if !shouldersDown { situpState.formIssues.append("Lower shoulders to ground") }
            }
            
        case .rising:
            // Check if vertical position reached
            let reachedVertical = torsoAngle > APFTStandards.situpTorsoVerticalMin
            
            if reachedVertical && kneesProper {
                situpState.phase = SitupPhase.lowering.rawValue
                situpState.additionalData["verticalReached"] = true
            } else {
                if !reachedVertical { situpState.formIssues.append("Sit up higher") }
                if !kneesProper {
                    // Knees angle not maintained - invalidate rep
                    situpState.phase = SitupPhase.down.rawValue
                    situpState.inValidRep = false
                }
            }
            
        case .lowering:
            // Check return to starting position
            let shouldersDown = torsoAngle < APFTStandards.situpTorsoHorizontalMax
            let verticalReached = situpState.additionalData["verticalReached"] as? Bool ?? false
            
            if shouldersDown && kneesProper && verticalReached {
                // Valid rep completed
                situpState.repCount += 1
                situpState.phase = SitupPhase.down.rawValue
                situpState.inValidRep = false
                situpState.additionalData.removeValue(forKey: "verticalReached")
                return true
            } else {
                if !shouldersDown { situpState.formIssues.append("Lower shoulders to ground") }
                if !kneesProper {
                    // Knees angle not maintained - invalidate rep
                    situpState.phase = SitupPhase.down.rawValue
                    situpState.inValidRep = false
                    situpState.additionalData.removeValue(forKey: "verticalReached")
                }
            }
            
        case .invalid:
            situpState.phase = SitupPhase.down.rawValue
        }
        
        return false
    }
    
    // MARK: - Main Processing Function
    func processFrame(body: DetectedBody, exerciseType: String, barHeightY: Float = 0.2) -> [String: Any] {
        var repCompleted = false
        var totalReps = 0
        var currentPhase = ""
        var inValidRep = false
        var formIssues: [String] = []
        
        switch exerciseType.lowercased() {
        case "pushup", "pushups":
            repCompleted = validatePushup(body: body)
            totalReps = pushupRepCount
            currentPhase = pushupPhase
            inValidRep = pushupState.inValidRep
            formIssues = pushupFormIssues
            
        case "pullup", "pullups":
            repCompleted = validatePullup(body: body, barHeightY: barHeightY)
            totalReps = pullupRepCount
            currentPhase = pullupPhase
            inValidRep = pullupState.inValidRep
            formIssues = pullupFormIssues
            
        case "situp", "situps":
            repCompleted = validateSitup(body: body)
            totalReps = situpRepCount
            currentPhase = situpPhase
            inValidRep = situpState.inValidRep
            formIssues = situpFormIssues
            
        default:
            formIssues = ["Unknown exercise type: \(exerciseType)"]
        }
        
        return [
            "repCompleted": repCompleted,
            "totalReps": totalReps,
            "currentPhase": currentPhase,
            "inValidRep": inValidRep,
            "formIssues": formIssues
        ]
    }
    
    // MARK: - Reset Functions
    func resetExercise(_ exerciseType: String) {
        switch exerciseType.lowercased() {
        case "pushup", "pushups":
            pushupState = ExerciseState(phase: PushupPhase.up.rawValue)
        case "pullup", "pullups":
            pullupState = ExerciseState(phase: PullupPhase.down.rawValue)
        case "situp", "situps":
            situpState = ExerciseState(phase: SitupPhase.down.rawValue)
        default:
            break
        }
    }
    
    func resetAllExercises() {
        pushupState = ExerciseState(phase: PushupPhase.up.rawValue)
        pullupState = ExerciseState(phase: PullupPhase.down.rawValue)
        situpState = ExerciseState(phase: SitupPhase.down.rawValue)
    }
} 