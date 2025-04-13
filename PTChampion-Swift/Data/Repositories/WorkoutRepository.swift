import Foundation

// Protocol defining the interface for workout data operations
protocol WorkoutRepositoryProtocol {
    func saveWorkout(request: SaveWorkoutRequest) async throws -> WorkoutResponse
    func getWorkoutHistory(page: Int, pageSize: Int) async throws -> [WorkoutResponse] // Adjust return type if backend pagination differs
}

// Concrete implementation using the APIClient
class WorkoutRepository: WorkoutRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func saveWorkout(request: SaveWorkoutRequest) async throws -> WorkoutResponse {
        // Input validation could be added here if needed
        return try await apiClient.saveWorkout(workoutData: request)
    }

    func getWorkoutHistory(page: Int = 1, pageSize: Int = 20) async throws -> [WorkoutResponse] {
        // Handle pagination logic if the API returns a wrapper object
        // Example: If API returns a PaginatedWorkoutResponse containing the array:
        // let response = try await apiClient.getWorkoutHistory(page: page, pageSize: pageSize)
        // return response.workouts 
        return try await apiClient.getWorkoutHistory(page: page, pageSize: pageSize)
    }
} 