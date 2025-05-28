import Foundation
import SwiftData

/// Represents the result of a completed workout session
struct WorkoutResult {
    let id: UUID
    let exerciseType: ExerciseType
    let totalReps: Int
    let duration: TimeInterval
    let timestamp: Date
    let repDetails: [RepDetail]
    let isPersonalBest: Bool
    
    init(id: UUID = UUID(), exerciseType: ExerciseType, totalReps: Int, duration: TimeInterval, timestamp: Date = Date(), repDetails: [RepDetail] = [], isPersonalBest: Bool = false) {
        self.id = id
        self.exerciseType = exerciseType
        self.totalReps = totalReps
        self.duration = duration
        self.timestamp = timestamp
        self.repDetails = repDetails
        self.isPersonalBest = isPersonalBest
    }
}

/// Represents detailed information about a single repetition
struct RepDetail {
    let repNumber: Int
    let formQuality: Double // 0.0 to 1.0
    let timestamp: Date
    
    init(repNumber: Int, formQuality: Double, timestamp: Date = Date()) {
        self.repNumber = repNumber
        self.formQuality = formQuality
        self.timestamp = timestamp
    }
}

// MARK: - SwiftData Models (for persistence)
// Note: WorkoutResultSwiftData is defined in WorkoutResultSwiftData.swift

@Model
class RepDetailSwiftData {
    @Attribute(.unique) var id: UUID
    var workoutResultId: UUID
    var repNumber: Int
    var formQuality: Double
    var timestamp: Date
    
    init(id: UUID = UUID(), workoutResultId: UUID, repNumber: Int, formQuality: Double, timestamp: Date = Date()) {
        self.id = id
        self.workoutResultId = workoutResultId
        self.repNumber = repNumber
        self.formQuality = formQuality
        self.timestamp = timestamp
    }
} 