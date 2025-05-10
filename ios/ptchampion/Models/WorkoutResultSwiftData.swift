import Foundation
import SwiftData

@Model
final class WorkoutResultSwiftData {
    // Add unique ID property
    @Attribute(.unique) var id: UUID = UUID()
    var exerciseType: String // Corresponds to ExerciseType.rawValue
    var startTime: Date
    var endTime: Date
    var durationSeconds: Int
    var repCount: Int? // Optional for runs
    var score: Double? // Optional for runs or unscored exercises
    var formQuality: Double? // Optional for runs or unscored exercises
    var distanceMeters: Double? // Optional, specifically for runs
    var isPublic: Bool // <-- ADDED
    var metadata: String? // Optional metadata for additional workout info (JSON or base64)

    init(exerciseType: String,
         startTime: Date,
         endTime: Date,
         durationSeconds: Int,
         repCount: Int? = nil,
         score: Double? = nil,
         formQuality: Double? = nil,
         distanceMeters: Double? = nil,
         isPublic: Bool = false,
         metadata: String? = nil) {
        self.exerciseType = exerciseType
        self.startTime = startTime
        self.endTime = endTime
        self.durationSeconds = durationSeconds
        self.repCount = repCount
        self.score = score
        self.formQuality = formQuality
        self.distanceMeters = distanceMeters
        self.isPublic = isPublic
        self.metadata = metadata
    }
    
    // Add initializer with custom ID
    init(id: String? = nil,
         exerciseType: String,
         startTime: Date,
         endTime: Date,
         durationSeconds: Int,
         repCount: Int? = nil,
         score: Double? = nil,
         formQuality: Double? = nil,
         distanceMeters: Double? = nil,
         isPublic: Bool = false,
         metadata: String? = nil) {
        if let idString = id, let uuid = UUID(uuidString: idString) {
            self.id = uuid
        }
        self.exerciseType = exerciseType
        self.startTime = startTime
        self.endTime = endTime
        self.durationSeconds = durationSeconds
        self.repCount = repCount
        self.score = score
        self.formQuality = formQuality
        self.distanceMeters = distanceMeters
        self.isPublic = isPublic
        self.metadata = metadata
    }

    // Convenience computed property to get ExerciseType enum
    var exercise: ExerciseType? {
        ExerciseType(rawValue: exerciseType)
    }
} 