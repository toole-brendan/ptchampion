// ios/ptchampion/Grading/APFTRepValidator+LandscapeFix.swift

import Foundation
import UIKit
import Vision
import CoreGraphics
import simd

extension APFTRepValidator {
    
    /// Calculate body alignment specifically for pushup exercises with landscape support
    func getPushupBodyAlignment(body: DetectedBody) -> Float? {
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
        
        let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .portrait
        
        // For pushups, we want to measure deviation from a straight line
        // Calculate the perpendicular distance from hip to the shoulder-ankle line
        let shoulderToAnkle = simd_float2(
            Float(ankleMid.x - shoulderMid.x),
            Float(ankleMid.y - shoulderMid.y)
        )
        
        let shoulderToHip = simd_float2(
            Float(hipMid.x - shoulderMid.x),
            Float(hipMid.y - shoulderMid.y)
        )
        
        let shoulderToAnkleLength = simd_length(shoulderToAnkle)
        guard shoulderToAnkleLength > 0 else { return 0 }
        
        // Project hip onto shoulder-ankle line
        let shoulderToAnkleNorm = shoulderToAnkle / shoulderToAnkleLength
        let projection = simd_dot(shoulderToHip, shoulderToAnkleNorm)
        let projectionPoint = shoulderToAnkleNorm * projection
        
        // Calculate perpendicular distance
        let perpVector = shoulderToHip - projectionPoint
        let perpDistance = simd_length(perpVector)
        
        // Convert to angle-like measurement (0-90 degrees scale)
        // A perpendicular distance of 0.1 (10% of body length) ≈ 10-15 degrees deviation
        let bodyLength = shoulderToAnkleLength
        let ratio = perpDistance / bodyLength
        
        // Scale to degrees (approximate)
        // Make this MUCH more lenient - a ratio of 0.2 (20% sag) should still be acceptable
        let deviation = ratio * 50.0  // Much more lenient scaling
        
        print("DEBUG: Pushup body alignment - Orientation: \(orientation.rawValue)")
        print("  Shoulder: \(shoulderMid), Hip: \(hipMid), Ankle: \(ankleMid)")
        print("  Perp distance: \(perpDistance), Body length: \(bodyLength)")
        print("  Calculated deviation: \(deviation)°")
        
        return deviation
    }
    
    /// More lenient arm angle calculation for different arm positions
    func getAdjustedArmAngle(shoulder: CGPoint, elbow: CGPoint, wrist: CGPoint, orientation: UIInterfaceOrientation) -> Float {
        let angle = calculateAngle(point1: shoulder, vertex: elbow, point3: wrist)
        
        // In landscape mode, arm angles might be measured differently
        // Adjust based on orientation if needed
        if orientation.isLandscape {
            // Landscape adjustments can be made here if needed
            return angle
        }
        
        return angle
    }
    
    /// Check if movement is sufficient based on orientation
    func checkMovementSufficient(
        currentPos: CGPoint,
        startPos: CGPoint,
        orientation: UIInterfaceOrientation,
        threshold: Float
    ) -> Bool {
        // In portrait, movement is primarily vertical
        // In landscape, movement might be primarily horizontal
        
        let verticalMovement = abs(currentPos.y - startPos.y)
        let horizontalMovement = abs(currentPos.x - startPos.x)
        
        let movement: CGFloat
        switch orientation {
        case .portrait, .portraitUpsideDown:
            movement = verticalMovement
        case .landscapeLeft, .landscapeRight:
            // In landscape, use the larger of the two movements
            movement = max(verticalMovement, horizontalMovement)
        @unknown default:
            movement = max(verticalMovement, horizontalMovement)
        }
        
        print("DEBUG: Movement check - V: \(verticalMovement), H: \(horizontalMovement), Used: \(movement), Threshold: \(threshold)")
        
        return Float(movement) > threshold
    }
}

// MARK: - Updated Standards for Real-World Use
extension APFTRepValidator {
    struct RealWorldStandards {
        // More lenient standards that work in practice
        static let pushupArmExtensionAngle: Float = 140.0      // Very lenient arm extension
        static let pushupArmParallelAngle: Float = 110.0       // Lenient parallel position
        static let pushupBodyAlignmentTolerance: Float = 30.0  // Allow more body deviation
        static let pushupStartPositionTolerance: Float = 40.0  // Very lenient for start position
        static let pushupMinDescentThreshold: Float = 0.01     // Minimal movement required
        static let pushupPositionTolerance: Float = 0.03       // Lenient return position
    }
}
