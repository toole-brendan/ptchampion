import Foundation
import SwiftData

@Model
final class WorkoutDataPoint {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var exerciseName: String
    var repNumber: Int // Stores the rep number (e.g., 1, 2, 3...)
    var formQuality: Double // From 0.0 to 1.0
    var phase: String? // Phase description at the time of rep completion
    var workoutID: UUID // Foreign key to WorkoutResultSwiftData.id

    init(id: UUID = UUID(), 
         timestamp: Date = Date(), 
         exerciseName: String, 
         repNumber: Int, 
         formQuality: Double, 
         phase: String? = nil,
         workoutID: UUID) {
        self.id = id
        self.timestamp = timestamp
        self.exerciseName = exerciseName
        self.repNumber = repNumber
        self.formQuality = formQuality
        self.phase = phase
        self.workoutID = workoutID
    }
} 