import Foundation
import Vision
import UIKit

class FullBodyFramingValidator: ObservableObject {
    @Published var framingStatus: FramingStatus = .notDetected
    @Published var guideFeedback: String = "Position yourself in frame"
    @Published var requiredAdjustment: FramingAdjustment = .none
    
    enum FramingStatus {
        case perfect
        case needsAdjustment
        case notDetected
    }
    
    enum FramingAdjustment {
        case none
        case moveCloser
        case moveBack
        case moveLeft
        case moveRight
        case rotateDevice
    }
    
    // MARK: - Validate Full Body Framing
    func validateFraming(body: DetectedBody?, exercise: ExerciseType, orientation: UIDeviceOrientation) -> Bool {
        guard let body = body else {
            framingStatus = .notDetected
            guideFeedback = "Position yourself in frame"
            return false
        }
        
        // Get required joints for exercise
        let requiredJoints = getRequiredJoints(for: exercise)
        let visibleJoints = requiredJoints.filter { body.point($0) != nil }
        
        // Check if all required joints are visible
        if visibleJoints.count < requiredJoints.count {
            framingStatus = .needsAdjustment
            guideFeedback = "Ensure your full body is visible"
            requiredAdjustment = calculateRequiredAdjustment(body: body, exercise: exercise)
            return false
        }
        
        // Check if body is well-centered and sized appropriately
        let boundingBox = calculateBoundingBox(body: body, joints: requiredJoints)
        let frameQuality = evaluateFrameQuality(boundingBox: boundingBox, orientation: orientation)
        
        switch frameQuality {
        case .tooClose:
            framingStatus = .needsAdjustment
            guideFeedback = "Step back from camera"
            requiredAdjustment = .moveBack
            return false
        case .tooFar:
            framingStatus = .needsAdjustment
            guideFeedback = "Move closer to camera"
            requiredAdjustment = .moveCloser
            return false
        case .offCenter(let direction):
            framingStatus = .needsAdjustment
            guideFeedback = "Center yourself in frame"
            requiredAdjustment = direction
            return false
        case .good:
            framingStatus = .perfect
            guideFeedback = "Perfect positioning!"
            requiredAdjustment = .none
            return true
        }
    }
    
    // MARK: - Helper Methods
    private func getRequiredJoints(for exercise: ExerciseType) -> [VNHumanBodyPoseObservation.JointName] {
        switch exercise {
        case .pushup:
            return [
                .leftWrist, .rightWrist,
                .leftElbow, .rightElbow,
                .leftShoulder, .rightShoulder,
                .leftHip, .rightHip,
                .leftKnee, .rightKnee,
                .leftAnkle, .rightAnkle
            ]
        case .pullup:
            return [
                .leftWrist, .rightWrist,
                .leftElbow, .rightElbow,
                .leftShoulder, .rightShoulder,
                .leftHip, .rightHip
            ]
        case .situp:
            return [
                .leftShoulder, .rightShoulder,
                .leftHip, .rightHip,
                .leftKnee, .rightKnee,
                .leftAnkle, .rightAnkle
            ]
        default:
            return []
        }
    }
    
    private func calculateBoundingBox(body: DetectedBody, joints: [VNHumanBodyPoseObservation.JointName]) -> CGRect {
        var minX: CGFloat = 1.0
        var maxX: CGFloat = 0.0
        var minY: CGFloat = 1.0
        var maxY: CGFloat = 0.0
        
        for joint in joints {
            if let point = body.point(joint) {
                minX = min(minX, point.location.x)
                maxX = max(maxX, point.location.x)
                minY = min(minY, point.location.y)
                maxY = max(maxY, point.location.y)
            }
        }
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    private enum FrameQuality {
        case good
        case tooClose
        case tooFar
        case offCenter(FramingAdjustment)
    }
    
    private func evaluateFrameQuality(boundingBox: CGRect, orientation: UIDeviceOrientation) -> FrameQuality {
        // Optimal body size should take up 60-80% of frame
        let optimalMinSize: CGFloat = 0.6
        let optimalMaxSize: CGFloat = 0.8
        
        let bodyHeight = boundingBox.height
        let bodyWidth = boundingBox.width
        
        // Check size
        if orientation.isPortrait {
            if bodyHeight > optimalMaxSize {
                return .tooClose
            } else if bodyHeight < optimalMinSize {
                return .tooFar
            }
        } else {
            if bodyWidth > optimalMaxSize {
                return .tooClose
            } else if bodyWidth < optimalMinSize {
                return .tooFar
            }
        }
        
        // Check centering
        let centerX = boundingBox.midX
        let centerY = boundingBox.midY
        let tolerance: CGFloat = 0.15
        
        if centerX < 0.5 - tolerance {
            return .offCenter(.moveRight)
        } else if centerX > 0.5 + tolerance {
            return .offCenter(.moveLeft)
        }
        
        return .good
    }
    
    private func calculateRequiredAdjustment(body: DetectedBody, exercise: ExerciseType) -> FramingAdjustment {
        let requiredJoints = getRequiredJoints(for: exercise)
        let visibleJoints = requiredJoints.filter { body.point($0) != nil }
        
        // If less than half the joints are visible, suggest moving back
        if visibleJoints.count < requiredJoints.count / 2 {
            return .moveBack
        }
        
        // Check which joints are missing to suggest direction
        let missingJoints = Set(requiredJoints).subtracting(Set(visibleJoints))
        
        // Analyze missing joints to suggest movement
        let hasLeftMissing = missingJoints.contains { jointName in
            jointName.rawValue.rawValue.contains("left")
        }
        let hasRightMissing = missingJoints.contains { jointName in
            jointName.rawValue.rawValue.contains("right")
        }
        let upperJointNames = ["shoulder", "elbow", "wrist"]
        let hasUpperMissing = missingJoints.contains { jointName in
            upperJointNames.contains { upperName in
                jointName.rawValue.rawValue.contains(upperName)
            }
        }
        let lowerJointNames = ["hip", "knee", "ankle"]
        let hasLowerMissing = missingJoints.contains { jointName in
            lowerJointNames.contains { lowerName in
                jointName.rawValue.rawValue.contains(lowerName)
            }
        }
        
        if hasLeftMissing && !hasRightMissing {
            return .moveRight
        } else if hasRightMissing && !hasLeftMissing {
            return .moveLeft
        } else if hasUpperMissing && !hasLowerMissing {
            return .moveBack // Camera too high or user too low
        } else if hasLowerMissing && !hasUpperMissing {
            return .moveBack // Camera too low or user too high
        }
        
        return .moveBack // Default to moving back for better framing
    }
    
    // MARK: - Public Helpers
    func reset() {
        framingStatus = .notDetected
        guideFeedback = "Position yourself in frame"
        requiredAdjustment = .none
    }
    
    func getFramingQualityScore(body: DetectedBody?, exercise: ExerciseType, orientation: UIDeviceOrientation) -> Double {
        guard let body = body else { return 0.0 }
        
        let requiredJoints = getRequiredJoints(for: exercise)
        let visibleJoints = requiredJoints.filter { body.point($0) != nil }
        let visibilityScore = Double(visibleJoints.count) / Double(requiredJoints.count)
        
        let boundingBox = calculateBoundingBox(body: body, joints: requiredJoints)
        let frameQuality = evaluateFrameQuality(boundingBox: boundingBox, orientation: orientation)
        
        let qualityScore: Double
        switch frameQuality {
        case .good:
            qualityScore = 1.0
        case .tooClose, .tooFar:
            qualityScore = 0.7
        case .offCenter:
            qualityScore = 0.8
        }
        
        return visibilityScore * qualityScore
    }
} 