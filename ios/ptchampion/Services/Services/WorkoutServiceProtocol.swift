import Foundation
import Combine

// Protocol defining the interface for workout data interactions
protocol WorkoutServiceProtocol {
    // Saves a completed workout session to the backend.
    // - Parameter result: The data representing the completed workout.
    // - Parameter authToken: The user's authentication token.
    func saveWorkout(result: InsertUserExerciseRequest, authToken: String) async throws -> Void // Use correct type: InsertUserExerciseRequest
    
    // Fetches the workout history for the logged-in user.
    // - Parameter authToken: The user's authentication token.
    // - Returns: An array of past workout records.
    func fetchWorkoutHistory(authToken: String) async throws -> [UserExerciseRecord] // Use correct type: UserExerciseRecord
    
    // TODO: Consider adding pagination to fetchWorkoutHistory if needed
    // func fetchWorkoutHistory(authToken: String, page: Int, pageSize: Int) async throws -> PaginatedUserExerciseResponse
    
    // Add other workout-related network calls if needed

    func getWorkoutById(id: String) async throws -> UserExerciseRecord
} 