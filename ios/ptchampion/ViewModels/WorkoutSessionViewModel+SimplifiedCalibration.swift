import Foundation
import SwiftUI
import Combine

extension WorkoutSessionViewModel {
    
    // MARK: - Simplified Calibration Properties
    var isQuickCalibrated: Bool {
        // Always return true since we use quick calibration with smart defaults
        return true
    }
    
    // MARK: - Simplified Calibration Methods
    func applyQuickCalibration(from manager: QuickCalibrationManager) {
        print("DEBUG: [WorkoutSessionViewModel] Applying quick calibration for \(exerciseType.displayName)")
        
        let profile = manager.getCurrentProfile(for: exerciseType)
        
        // Create a simplified calibration data from the quick profile
        let quickCalibrationData = createQuickCalibrationData(from: profile)
        
        // Apply to real-time feedback manager
        realTimeFeedbackManager.startFeedback(for: exerciseType, with: quickCalibrationData)
        
        // Update grader with calibration data if supported
        if let calibratableGrader = exerciseGrader as? CalibratableExerciseGrader {
            calibratableGrader.applyCalibration(quickCalibrationData)
        }
        
        print("DEBUG: [WorkoutSessionViewModel] Quick calibration applied successfully")
    }
    
    private func createQuickCalibrationData(from profile: QuickCalibrationManager.SimpleCalibrationProfile) -> CalibrationData {
        // Create default angle adjustments based on exercise type and orientation
        let angleAdjustments = createDefaultAngleAdjustments(for: profile.exerciseType, orientation: profile.deviceOrientation)
        
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
            timestamp: profile.created,
            exercise: profile.exerciseType,
            deviceHeight: 1.0, // Default height
            deviceAngle: profile.deviceOrientation.isLandscape ? 90.0 : 0.0,
            deviceDistance: Float(profile.optimalDistance),
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
    
    // MARK: - Orientation Update for Quick Calibration
    func updateQuickCalibrationForOrientation(_ manager: QuickCalibrationManager) {
        manager.updateForOrientationChange(exercise: exerciseType)
        applyQuickCalibration(from: manager)
    }
}

// MARK: - Note: CalibratableExerciseGrader protocol is defined in WorkoutSessionViewModel+Calibration.swift 