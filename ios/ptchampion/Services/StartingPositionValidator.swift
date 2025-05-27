import Foundation
import Vision
import CoreGraphics

/// Validates if the user is in the correct starting position for each exercise
public class StartingPositionValidator: ObservableObject {
    
    // MARK: - Position Requirements
    struct PositionRequirements {
        let armAngleMin: Float
        let armAngleMax: Float
        let bodyAlignmentMax: Float
        let additionalChecks: [(DetectedBody) -> (isValid: Bool, feedback: String?)]
        
        static let pushup = PositionRequirements(
            armAngleMin: 140.0,
            armAngleMax: 180.0,
            bodyAlignmentMax: 30.0,
            additionalChecks: [
                { body in
                    // Check if hands are roughly shoulder-width apart
                    guard let leftWrist = body.point(.leftWrist),
                          let rightWrist = body.point(.rightWrist),
                          let leftShoulder = body.point(.leftShoulder),
                          let rightShoulder = body.point(.rightShoulder) else {
                        return (false, "Cannot detect hands and shoulders")
                    }
                    
                    let shoulderWidth = abs(leftShoulder.location.x - rightShoulder.location.x)
                    let handWidth = abs(leftWrist.location.x - rightWrist.location.x)
                    let ratio = handWidth / shoulderWidth
                    
                    if ratio < 0.8 {
                        return (false, "Hands too close together")
                    } else if ratio > 1.5 {
                        return (false, "Hands too far apart")
                    }
                    return (true, nil)
                }
            ]
        )
        
        static let pullup = PositionRequirements(
            armAngleMin: 150.0,
            armAngleMax: 180.0,
            bodyAlignmentMax: 20.0,
            additionalChecks: [
                { body in
                    // Check if feet are off the ground
                    guard let leftAnkle = body.point(.leftAnkle),
                          let rightAnkle = body.point(.rightAnkle) else {
                        return (false, "Cannot detect feet")
                    }
                    
                    // Feet should be in lower portion of frame (off ground)
                    let avgAnkleY = (leftAnkle.location.y + rightAnkle.location.y) / 2
                    if avgAnkleY < 0.7 {
                        return (false, "Feet must be off the ground")
                    }
                    return (true, nil)
                },
                { body in
                    // Check if hands are visible (gripping bar)
                    guard let leftWrist = body.point(.leftWrist),
                          let rightWrist = body.point(.rightWrist) else {
                        return (false, "Cannot detect hands on bar")
                    }
                    
                    // Hands should be in upper portion of frame
                    let avgWristY = (leftWrist.location.y + rightWrist.location.y) / 2
                    if avgWristY > 0.3 {
                        return (false, "Position hands on the pull-up bar")
                    }
                    return (true, nil)
                }
            ]
        )
        
        static let situp = PositionRequirements(
            armAngleMin: 0.0,  // Not used for situps
            armAngleMax: 0.0,  // Not used for situps
            bodyAlignmentMax: 180.0,  // Not used for situps
            additionalChecks: [
                { body in
                    // Check if back is on ground (torso angle)
                    guard let leftShoulder = body.point(.leftShoulder),
                          let rightShoulder = body.point(.rightShoulder),
                          let leftHip = body.point(.leftHip),
                          let rightHip = body.point(.rightHip) else {
                        return (false, "Cannot detect torso position")
                    }
                    
                    let shoulderMid = CGPoint(
                        x: (leftShoulder.location.x + rightShoulder.location.x) / 2,
                        y: (leftShoulder.location.y + rightShoulder.location.y) / 2
                    )
                    let hipMid = CGPoint(
                        x: (leftHip.location.x + rightHip.location.x) / 2,
                        y: (leftHip.location.y + rightHip.location.y) / 2
                    )
                    
                    // Calculate torso angle from horizontal
                    let torsoVector = simd_float2(Float(shoulderMid.x - hipMid.x), Float(shoulderMid.y - hipMid.y))
                    let horizontalVector = simd_float2(1, 0)
                    
                    let dotProduct = simd_dot(torsoVector, horizontalVector)
                    let torsoMagnitude = simd_length(torsoVector)
                    
                    guard torsoMagnitude > 0 else { return (false, "Cannot calculate torso angle") }
                    
                    let cosAngle = simd_clamp(abs(dotProduct) / torsoMagnitude, 0.0, 1.0)
                    let torsoAngle = acos(cosAngle) * 180.0 / Float.pi
                    
                    if torsoAngle > 20.0 {
                        return (false, "Lower your back to the ground")
                    }
                    return (true, nil)
                },
                { body in
                    // Check knee angle
                    guard let leftHip = body.point(.leftHip),
                          let rightHip = body.point(.rightHip),
                          let leftKnee = body.point(.leftKnee),
                          let rightKnee = body.point(.rightKnee),
                          let leftAnkle = body.point(.leftAnkle),
                          let rightAnkle = body.point(.rightAnkle) else {
                        return (false, "Cannot detect leg position")
                    }
                    
                    let leftKneeAngle = StartingPositionValidator.calculateAngle(
                        point1: leftHip.location,
                        vertex: leftKnee.location,
                        point3: leftAnkle.location
                    )
                    let rightKneeAngle = StartingPositionValidator.calculateAngle(
                        point1: rightHip.location,
                        vertex: rightKnee.location,
                        point3: rightAnkle.location
                    )
                    let avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2
                    
                    if avgKneeAngle < 80.0 {
                        return (false, "Bend your knees more")
                    } else if avgKneeAngle > 100.0 {
                        return (false, "Straighten your knees slightly")
                    }
                    return (true, nil)
                }
            ]
        )
    }
    
    // MARK: - Position Status
    enum PositionStatus {
        case correct
        case needsAdjustment(feedback: [String])
        case notDetected
    }
    
    @Published var currentStatus: PositionStatus = .notDetected
    @Published var armAngle: Float = 0
    @Published var bodyAlignment: Float = 0
    @Published var kneeAngle: Float = 0  // For situps
    @Published var isInPosition: Bool = false
    @Published var timeInCorrectPosition: TimeInterval = 0
    
    private var positionTimer: Timer?
    private var lastCorrectPositionTime: Date?
    private let requiredHoldTime: TimeInterval = 2.0  // 2 seconds in correct position
    
    // MARK: - Validation
    func validatePosition(body: DetectedBody?, exerciseType: ExerciseType) {
        guard let body = body else {
            currentStatus = .notDetected
            isInPosition = false
            resetPositionTimer()
            return
        }
        
        var feedback: [String] = []
        let requirements: PositionRequirements
        
        switch exerciseType {
        case .pushup:
            requirements = .pushup
            // Check full body visibility
            if !isFullBodyVisible(body: body, forExercise: .pushup) {
                feedback.append("Position your entire body in frame")
            }
            
            // Check arm angle
            let armAngleResult = checkArmAngle(body: body, requirements: requirements)
            self.armAngle = armAngleResult.angle
            if let armFeedback = armAngleResult.feedback {
                feedback.append(armFeedback)
            }
            
            // Check body alignment
            let alignmentResult = checkBodyAlignment(body: body, requirements: requirements)
            self.bodyAlignment = alignmentResult.angle
            if let alignmentFeedback = alignmentResult.feedback {
                feedback.append(alignmentFeedback)
            }
            
        case .pullup:
            requirements = .pullup
            // Check full body visibility
            if !isFullBodyVisible(body: body, forExercise: .pullup) {
                feedback.append("Position your entire body in frame")
            }
            
            // Check arm angle
            let armAngleResult = checkArmAngle(body: body, requirements: requirements)
            self.armAngle = armAngleResult.angle
            if let armFeedback = armAngleResult.feedback {
                feedback.append(armFeedback)
            }
            
        case .situp:
            requirements = .situp
            // Check full body visibility
            if !isFullBodyVisible(body: body, forExercise: .situp) {
                feedback.append("Position your entire body in frame")
            }
            
            // For situps, we check knee angle instead of arm angle
            let kneeAngleResult = checkKneeAngle(body: body)
            self.kneeAngle = kneeAngleResult.angle
            if let kneeFeedback = kneeAngleResult.feedback {
                feedback.append(kneeFeedback)
            }
            
        default:
            currentStatus = .notDetected
            return
        }
        
        // Run additional checks
        for check in requirements.additionalChecks {
            let result = check(body)
            if !result.isValid, let checkFeedback = result.feedback {
                feedback.append(checkFeedback)
            }
        }
        
        // Update status
        if feedback.isEmpty {
            currentStatus = .correct
            updatePositionTimer()
        } else {
            currentStatus = .needsAdjustment(feedback: feedback)
            resetPositionTimer()
        }
    }
    
    // MARK: - Helper Methods
    private func isFullBodyVisible(body: DetectedBody, forExercise exercise: ExerciseType) -> Bool {
        switch exercise {
        case .pushup:
            // Check key points for pushup
            return body.point(.leftWrist) != nil &&
                   body.point(.rightWrist) != nil &&
                   body.point(.leftShoulder) != nil &&
                   body.point(.rightShoulder) != nil &&
                   body.point(.leftHip) != nil &&
                   body.point(.rightHip) != nil &&
                   body.point(.leftAnkle) != nil &&
                   body.point(.rightAnkle) != nil
            
        case .pullup:
            // Check key points for pullup
            return body.point(.leftWrist) != nil &&
                   body.point(.rightWrist) != nil &&
                   body.point(.leftShoulder) != nil &&
                   body.point(.rightShoulder) != nil &&
                   body.point(.leftHip) != nil &&
                   body.point(.rightHip) != nil
            
        case .situp:
            // Check key points for situp
            return body.point(.leftShoulder) != nil &&
                   body.point(.rightShoulder) != nil &&
                   body.point(.leftHip) != nil &&
                   body.point(.rightHip) != nil &&
                   body.point(.leftKnee) != nil &&
                   body.point(.rightKnee) != nil &&
                   body.point(.leftAnkle) != nil &&
                   body.point(.rightAnkle) != nil
            
        default:
            return false
        }
    }
    
    private func checkArmAngle(body: DetectedBody, requirements: PositionRequirements) -> (angle: Float, feedback: String?) {
        guard let leftShoulder = body.point(.leftShoulder),
              let rightShoulder = body.point(.rightShoulder),
              let leftElbow = body.point(.leftElbow),
              let rightElbow = body.point(.rightElbow),
              let leftWrist = body.point(.leftWrist),
              let rightWrist = body.point(.rightWrist) else {
            return (0, "Cannot detect arms")
        }
        
        let leftArmAngle = Self.calculateAngle(
            point1: leftShoulder.location,
            vertex: leftElbow.location,
            point3: leftWrist.location
        )
        let rightArmAngle = Self.calculateAngle(
            point1: rightShoulder.location,
            vertex: rightElbow.location,
            point3: rightWrist.location
        )
        let avgArmAngle = (leftArmAngle + rightArmAngle) / 2
        
        if avgArmAngle < requirements.armAngleMin {
            return (avgArmAngle, "Extend your arms more")
        } else if avgArmAngle > requirements.armAngleMax {
            return (avgArmAngle, nil)  // Over-extended is okay
        }
        
        return (avgArmAngle, nil)
    }
    
    private func checkBodyAlignment(body: DetectedBody, requirements: PositionRequirements) -> (angle: Float, feedback: String?) {
        guard let leftShoulder = body.point(.leftShoulder),
              let rightShoulder = body.point(.rightShoulder),
              let leftHip = body.point(.leftHip),
              let rightHip = body.point(.rightHip),
              let leftAnkle = body.point(.leftAnkle),
              let rightAnkle = body.point(.rightAnkle) else {
            return (0, "Cannot detect body alignment")
        }
        
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
        let verticalVector = simd_float2(0, 1)
        
        let dotProduct = simd_dot(bodyVector, verticalVector)
        let bodyMagnitude = simd_length(bodyVector)
        
        guard bodyMagnitude > 0 else { return (0, "Cannot calculate body alignment") }
        
        let cosAngle = simd_clamp(dotProduct / bodyMagnitude, -1.0, 1.0)
        let bodyAngle = acos(cosAngle) * 180.0 / Float.pi
        
        if bodyAngle > requirements.bodyAlignmentMax {
            return (bodyAngle, "Straighten your body")
        }
        
        return (bodyAngle, nil)
    }
    
    private func checkKneeAngle(body: DetectedBody) -> (angle: Float, feedback: String?) {
        guard let leftHip = body.point(.leftHip),
              let rightHip = body.point(.rightHip),
              let leftKnee = body.point(.leftKnee),
              let rightKnee = body.point(.rightKnee),
              let leftAnkle = body.point(.leftAnkle),
              let rightAnkle = body.point(.rightAnkle) else {
            return (0, "Cannot detect leg position")
        }
        
        let leftKneeAngle = Self.calculateAngle(
            point1: leftHip.location,
            vertex: leftKnee.location,
            point3: leftAnkle.location
        )
        let rightKneeAngle = Self.calculateAngle(
            point1: rightHip.location,
            vertex: rightKnee.location,
            point3: rightAnkle.location
        )
        let avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2
        
        if avgKneeAngle < 80.0 {
            return (avgKneeAngle, "Bend your knees to 90 degrees")
        } else if avgKneeAngle > 100.0 {
            return (avgKneeAngle, "Bend your knees to 90 degrees")
        }
        
        return (avgKneeAngle, nil)
    }
    
    private static func calculateAngle(point1: CGPoint, vertex: CGPoint, point3: CGPoint) -> Float {
        let vector1 = simd_float2(Float(point1.x - vertex.x), Float(point1.y - vertex.y))
        let vector2 = simd_float2(Float(point3.x - vertex.x), Float(point3.y - vertex.y))
        
        let dotProduct = simd_dot(vector1, vector2)
        let magnitude1 = simd_length(vector1)
        let magnitude2 = simd_length(vector2)
        
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0 }
        
        let cosAngle = simd_clamp(dotProduct / (magnitude1 * magnitude2), -1.0, 1.0)
        return acos(cosAngle) * 180.0 / Float.pi
    }
    
    // MARK: - Position Timer
    private func updatePositionTimer() {
        if lastCorrectPositionTime == nil {
            lastCorrectPositionTime = Date()
            positionTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.updateTimeInPosition()
            }
        }
    }
    
    private func resetPositionTimer() {
        positionTimer?.invalidate()
        positionTimer = nil
        lastCorrectPositionTime = nil
        timeInCorrectPosition = 0
        isInPosition = false
    }
    
    private func updateTimeInPosition() {
        guard let startTime = lastCorrectPositionTime else { return }
        timeInCorrectPosition = Date().timeIntervalSince(startTime)
        
        if timeInCorrectPosition >= requiredHoldTime && !isInPosition {
            isInPosition = true
        }
    }
    
    // MARK: - Reset
    func reset() {
        currentStatus = .notDetected
        armAngle = 0
        bodyAlignment = 0
        kneeAngle = 0
        isInPosition = false
        resetPositionTimer()
    }
    
    deinit {
        positionTimer?.invalidate()
    }
}
