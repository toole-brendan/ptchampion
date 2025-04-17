import Foundation
import Combine

// Protocol defining the interface for workout data interactions
protocol WorkoutServiceProtocol {
    // Saves a completed workout session result
    // Requires authentication token
    func saveWorkout(result: WorkoutResultPayload, authToken: String) async throws -> Void // Or return saved WorkoutRecord?

    // Fetches the user's workout history
    // Requires authentication token
    func fetchWorkoutHistory(authToken: String) async throws -> [WorkoutRecord]

    // Optional: Fetch details for a specific workout
    // func fetchWorkoutDetail(id: String, authToken: String) async throws -> WorkoutRecord

    func getWorkoutById(id: String) async throws -> UserExerciseRecord
} 