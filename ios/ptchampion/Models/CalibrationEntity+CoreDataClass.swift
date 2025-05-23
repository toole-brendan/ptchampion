import Foundation
import CoreData

@objc(CalibrationEntity)
public class CalibrationEntity: NSManagedObject {
    
    // MARK: - Convenience Initializers
    convenience init(context: NSManagedObjectContext, from calibrationData: CalibrationData) {
        self.init(context: context)
        
        self.id = calibrationData.id
        self.timestamp = calibrationData.timestamp
        self.exercise = calibrationData.exercise.rawValue
        self.deviceHeight = calibrationData.deviceHeight
        self.deviceAngle = calibrationData.deviceAngle
        self.deviceDistance = calibrationData.deviceDistance
        self.deviceStability = calibrationData.deviceStability
        self.userHeight = calibrationData.userHeight
        self.armSpan = calibrationData.armSpan
        self.torsoLength = calibrationData.torsoLength
        self.legLength = calibrationData.legLength
        self.calibrationScore = calibrationData.calibrationScore
        self.confidenceLevel = calibrationData.confidenceLevel
        self.frameCount = Int32(calibrationData.frameCount)
        
        // Store complex data as JSON
        do {
            let angleAdjustmentsData = try JSONEncoder().encode(calibrationData.angleAdjustments)
            self.angleAdjustmentsData = angleAdjustmentsData
            
            let visibilityThresholdsData = try JSONEncoder().encode(calibrationData.visibilityThresholds)
            self.visibilityThresholdsData = visibilityThresholdsData
            
            let poseNormalizationData = try JSONEncoder().encode(calibrationData.poseNormalization)
            self.poseNormalizationData = poseNormalizationData
            
            let validationRangesData = try JSONEncoder().encode(calibrationData.validationRanges)
            self.validationRangesData = validationRangesData
            
            // Store full calibration data as JSON for complete recovery
            let fullData = try JSONEncoder().encode(calibrationData)
            self.rawData = fullData
        } catch {
            print("❌ Failed to encode calibration data: \(error)")
        }
    }
    
    // MARK: - Conversion to CalibrationData
    func toCalibrationData() -> CalibrationData? {
        // Try to decode from full raw data first
        if let rawData = self.rawData {
            do {
                return try JSONDecoder().decode(CalibrationData.self, from: rawData)
            } catch {
                print("⚠️ Failed to decode full calibration data, attempting partial reconstruction: \(error)")
            }
        }
        
        // Fallback to reconstructing from individual fields
        return reconstructCalibrationData()
    }
    
    private func reconstructCalibrationData() -> CalibrationData? {
        guard let id = self.id,
              let timestamp = self.timestamp,
              let exerciseString = self.exercise,
              let exerciseType = ExerciseType(rawValue: exerciseString) else {
            print("❌ Missing required calibration data fields")
            return nil
        }
        
        do {
            // Decode complex structures
            let angleAdjustments: AngleAdjustments
            if let angleData = self.angleAdjustmentsData {
                angleAdjustments = try JSONDecoder().decode(AngleAdjustments.self, from: angleData)
            } else {
                angleAdjustments = getDefaultAngleAdjustments(for: exerciseType)
            }
            
            let visibilityThresholds: VisibilityThresholds
            if let visibilityData = self.visibilityThresholdsData {
                visibilityThresholds = try JSONDecoder().decode(VisibilityThresholds.self, from: visibilityData)
            } else {
                visibilityThresholds = getDefaultVisibilityThresholds()
            }
            
            let poseNormalization: PoseNormalization
            if let normalizationData = self.poseNormalizationData {
                poseNormalization = try JSONDecoder().decode(PoseNormalization.self, from: normalizationData)
            } else {
                poseNormalization = getDefaultPoseNormalization()
            }
            
            let validationRanges: ValidationRanges
            if let rangesData = self.validationRangesData {
                validationRanges = try JSONDecoder().decode(ValidationRanges.self, from: rangesData)
            } else {
                validationRanges = getDefaultValidationRanges()
            }
            
            return CalibrationData(
                id: id,
                timestamp: timestamp,
                exercise: exerciseType,
                deviceHeight: self.deviceHeight,
                deviceAngle: self.deviceAngle,
                deviceDistance: self.deviceDistance,
                deviceStability: self.deviceStability,
                userHeight: self.userHeight,
                armSpan: self.armSpan,
                torsoLength: self.torsoLength,
                legLength: self.legLength,
                angleAdjustments: angleAdjustments,
                visibilityThresholds: visibilityThresholds,
                poseNormalization: poseNormalization,
                calibrationScore: self.calibrationScore,
                confidenceLevel: self.confidenceLevel,
                frameCount: Int(self.frameCount),
                validationRanges: validationRanges
            )
        } catch {
            print("❌ Failed to reconstruct calibration data: \(error)")
            return nil
        }
    }
    
    // MARK: - Default Values
    private func getDefaultAngleAdjustments(for exercise: ExerciseType) -> AngleAdjustments {
        return AngleAdjustments(
            pushupElbowUp: 170.0,
            pushupElbowDown: 90.0,
            pushupBodyAlignment: 15.0,
            situpTorsoUp: 90.0,
            situpTorsoDown: 45.0,
            situpKneeAngle: 90.0,
            pullupArmExtended: 170.0,
            pullupArmFlexed: 90.0,
            pullupBodyVertical: 20.0
        )
    }
    
    private func getDefaultVisibilityThresholds() -> VisibilityThresholds {
        return VisibilityThresholds(
            minimumConfidence: 0.5,
            criticalJoints: 0.7,
            supportJoints: 0.5,
            faceJoints: 0.3
        )
    }
    
    private func getDefaultPoseNormalization() -> PoseNormalization {
        return PoseNormalization(
            shoulderWidth: 0.3,
            hipWidth: 0.25,
            armLength: 0.6,
            legLength: 0.8,
            headSize: 0.12
        )
    }
    
    private func getDefaultValidationRanges() -> ValidationRanges {
        return ValidationRanges(
            angleTolerances: [
                "pushup_elbow": 10.0,
                "situp_torso": 15.0,
                "pullup_arm": 10.0,
                "body_alignment": 20.0
            ],
            positionTolerances: [
                "horizontal_drift": 0.1,
                "vertical_drift": 0.1,
                "distance_variation": 0.2
            ],
            movementThresholds: [
                "max_speed": 30.0,
                "min_speed": 2.0,
                "stability_window": 5.0
            ]
        )
    }
}

// MARK: - Computed Properties
extension CalibrationEntity {
    var qualityLevel: CalibrationQuality {
        switch calibrationScore {
        case 90...100: return .excellent
        case 80..<90: return .good
        case 70..<80: return .acceptable
        case 60..<70: return .poor
        default: return .invalid
        }
    }
    
    var isUsable: Bool {
        return calibrationScore >= 60.0 && confidenceLevel >= 0.5
    }
    
    var devicePositionDescription: String {
        let position = DevicePositionDetector.Position.elevated(height: deviceHeight, angle: deviceAngle)
        return position.description
    }
} 