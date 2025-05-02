import Foundation
import SwiftData

@Model
final class WorkoutResultSwiftData {
    var exerciseType: String // Corresponds to ExerciseType.rawValue
    var startTime: Date
    var endTime: Date
    var durationSeconds: Int
    var repCount: Int? // Optional for runs
    var score: Double? // Optional for runs or unscored exercises
    var distanceMeters: Double? // Optional, specifically for runs

    init(exerciseType: String,
         startTime: Date,
         endTime: Date,
         durationSeconds: Int,
         repCount: Int? = nil,
         score: Double? = nil,
         distanceMeters: Double? = nil) {
        self.exerciseType = exerciseType
        self.startTime = startTime
        self.endTime = endTime
        self.durationSeconds = durationSeconds
        self.repCount = repCount
        self.score = score
        self.distanceMeters = distanceMeters
    }

    // Convenience computed property to get ExerciseType enum
    var exercise: ExerciseType? {
        ExerciseType(rawValue: exerciseType)
    }
} 