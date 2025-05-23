import Foundation
import CoreData
import UIKit

extension CalibrationEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CalibrationEntity> {
        return NSFetchRequest<CalibrationEntity>(entityName: "CalibrationEntity")
    }

    // MARK: - Basic Properties
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var exercise: String?
    
    // MARK: - Device Position Data
    @NSManaged public var deviceHeight: Float
    @NSManaged public var deviceAngle: Float
    @NSManaged public var deviceDistance: Float
    @NSManaged public var deviceStability: Float
    
    // MARK: - User Measurements
    @NSManaged public var userHeight: Float
    @NSManaged public var armSpan: Float
    @NSManaged public var torsoLength: Float
    @NSManaged public var legLength: Float
    
    // MARK: - Quality Metrics
    @NSManaged public var calibrationScore: Float
    @NSManaged public var confidenceLevel: Float
    @NSManaged public var frameCount: Int32
    
    // MARK: - Complex Data (stored as JSON)
    @NSManaged public var angleAdjustmentsData: Data?
    @NSManaged public var visibilityThresholdsData: Data?
    @NSManaged public var poseNormalizationData: Data?
    @NSManaged public var validationRangesData: Data?
    @NSManaged public var rawData: Data? // Full CalibrationData as JSON backup
    
    // MARK: - Metadata
    @NSManaged public var deviceModel: String?
    @NSManaged public var appVersion: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var isArchived: Bool
    @NSManaged public var notes: String?
}

// MARK: - Identifiable
extension CalibrationEntity: Identifiable {
    public var coreDataID: NSManagedObjectID {
        return objectID
    }
}

// MARK: - Validation
extension CalibrationEntity {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        // Set default values
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.isArchived = false
        
        // Set device metadata
        self.deviceModel = UIDevice.current.model
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    public override func willSave() {
        super.willSave()
        
        // Update timestamp on save
        if isUpdated {
            self.updatedAt = Date()
        }
    }
    
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try validateRequiredFields()
    }
    
    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateRequiredFields()
    }
    
    private func validateRequiredFields() throws {
        guard id != nil else {
            throw CalibrationValidationError.missingID
        }
        
        guard timestamp != nil else {
            throw CalibrationValidationError.missingTimestamp
        }
        
        guard let exerciseString = exercise, !exerciseString.isEmpty else {
            throw CalibrationValidationError.missingExercise
        }
        
        guard ExerciseType(rawValue: exerciseString) != nil else {
            throw CalibrationValidationError.invalidExercise(exerciseString)
        }
        
        guard calibrationScore >= 0 && calibrationScore <= 100 else {
            throw CalibrationValidationError.invalidScore(calibrationScore)
        }
        
        guard confidenceLevel >= 0 && confidenceLevel <= 1 else {
            throw CalibrationValidationError.invalidConfidence(confidenceLevel)
        }
        
        guard frameCount > 0 else {
            throw CalibrationValidationError.invalidFrameCount(Int(frameCount))
        }
    }
}

// MARK: - Validation Errors
enum CalibrationValidationError: LocalizedError {
    case missingID
    case missingTimestamp
    case missingExercise
    case invalidExercise(String)
    case invalidScore(Float)
    case invalidConfidence(Float)
    case invalidFrameCount(Int)
    
    var errorDescription: String? {
        switch self {
        case .missingID:
            return "Calibration ID is required"
        case .missingTimestamp:
            return "Calibration timestamp is required"
        case .missingExercise:
            return "Exercise type is required"
        case .invalidExercise(let exercise):
            return "Invalid exercise type: \(exercise)"
        case .invalidScore(let score):
            return "Invalid calibration score: \(score). Must be between 0 and 100"
        case .invalidConfidence(let confidence):
            return "Invalid confidence level: \(confidence). Must be between 0 and 1"
        case .invalidFrameCount(let count):
            return "Invalid frame count: \(count). Must be greater than 0"
        }
    }
}

// MARK: - Query Helpers
extension CalibrationEntity {
    static func predicateForExercise(_ exercise: ExerciseType) -> NSPredicate {
        return NSPredicate(format: "exercise == %@ AND isArchived == NO", exercise.rawValue)
    }
    
    static func predicateForQualityAbove(_ threshold: Float) -> NSPredicate {
        return NSPredicate(format: "calibrationScore >= %f AND isArchived == NO", threshold)
    }
    
    static func predicateForDateRange(from startDate: Date, to endDate: Date) -> NSPredicate {
        return NSPredicate(format: "timestamp >= %@ AND timestamp <= %@ AND isArchived == NO", startDate as NSDate, endDate as NSDate)
    }
    
    static func predicateForUsable() -> NSPredicate {
        return NSPredicate(format: "calibrationScore >= 60.0 AND confidenceLevel >= 0.5 AND isArchived == NO")
    }
}
