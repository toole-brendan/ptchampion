// ios/ptchampion/Grading/APFTRepValidator+LandscapeOverride.swift

import Foundation
import UIKit
import Vision

extension APFTRepValidator {
    
    /// Override validation logic for landscape mode - much more lenient
    func validatePushupLandscapeMode(body: DetectedBody) -> Bool {
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
        
        print("DEBUG: Landscape Pushup - Phase: \(pushupState.phase), Arm angle: \(avgArmAngle)°")
        
        // Get shoulder position for tracking movement
        let shoulderMidY = (leftShoulder.location.y + rightShoulder.location.y) / 2
        let shoulderMidX = (leftShoulder.location.x + rightShoulder.location.x) / 2
        
        // State machine logic with VERY lenient checks for landscape
        switch PushupPhase(rawValue: pushupState.phase) ?? .invalid {
        case .up:
            // Very lenient arm extension check for landscape
            let armsReasonablyExtended = avgArmAngle > 130.0  // Much lower threshold
            
            print("DEBUG: Landscape UP phase - Arms extended: \(armsReasonablyExtended) (angle: \(avgArmAngle)°)")
            
            if armsReasonablyExtended {
                // Ready to start descent - skip body alignment check entirely
                pushupState.additionalData["startShoulderHeight"] = shoulderMidY
                pushupState.additionalData["startShoulderX"] = shoulderMidX
                pushupState.phase = PushupPhase.descending.rawValue
                pushupState.inValidRep = true
                print("DEBUG: Landscape - Transitioning to DESCENDING phase")
            } else {
                pushupState.formIssues.append("Extend arms to begin")
            }
            
        case .descending:
            // Check if arms are bent enough (very lenient)
            let armsBent = avgArmAngle <= 120.0  // Much higher threshold
            
            // Check movement in both directions
            let startHeight = pushupState.additionalData["startShoulderHeight"] as? CGFloat ?? shoulderMidY
            let startX = pushupState.additionalData["startShoulderX"] as? CGFloat ?? shoulderMidX
            
            let verticalMovement = abs(shoulderMidY - startHeight)
            let horizontalMovement = abs(shoulderMidX - startX)
            let totalMovement = max(verticalMovement, horizontalMovement)
            
            let sufficientMovement = Float(totalMovement) > 0.01  // Very minimal movement required
            
            print("DEBUG: Landscape DESCENDING - Arms bent: \(armsBent) (angle: \(avgArmAngle)°), Movement: \(totalMovement)")
            
            if armsBent && sufficientMovement {
                pushupState.phase = PushupPhase.ascending.rawValue
                pushupState.additionalData["bottomReached"] = true
                print("DEBUG: Landscape - Transitioning to ASCENDING phase")
            } else {
                if !armsBent { pushupState.formIssues.append("Bend arms more") }
                if !sufficientMovement { pushupState.formIssues.append("Lower your body") }
            }
            
        case .ascending:
            // Check return to reasonably extended position
            let armsReasonablyExtended = avgArmAngle > 130.0
            let bottomReached = pushupState.additionalData["bottomReached"] as? Bool ?? false
            
            print("DEBUG: Landscape ASCENDING - Arms extended: \(armsReasonablyExtended) (angle: \(avgArmAngle)°)")
            
            if armsReasonablyExtended && bottomReached {
                // Valid rep completed
                pushupState.repCount += 1
                pushupState.phase = PushupPhase.up.rawValue
                pushupState.inValidRep = false
                pushupState.additionalData.removeValue(forKey: "bottomReached")
                pushupState.additionalData.removeValue(forKey: "startShoulderHeight")
                pushupState.additionalData.removeValue(forKey: "startShoulderX")
                print("DEBUG: Landscape - REP COMPLETED! Total: \(pushupState.repCount)")
                return true
            } else {
                if !armsReasonablyExtended { pushupState.formIssues.append("Extend arms to complete rep") }
            }
            
        case .invalid:
            pushupState.phase = PushupPhase.up.rawValue
        }
        
        return false
    }
}

// Extension to make orientation checks easier
extension UIInterfaceOrientation {
    var isLandscape: Bool {
        return self == .landscapeLeft || self == .landscapeRight
    }
}
