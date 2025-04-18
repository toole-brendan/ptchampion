import Foundation

// Implementation of WorkoutServiceProtocol using the shared NetworkClient
class WorkoutService: WorkoutServiceProtocol {

    private let networkClient: NetworkClient

    // Inject the NetworkClient
    init(networkClient: NetworkClient = NetworkClient()) {
        self.networkClient = networkClient
    }

    // MARK: - API Endpoints (Paths only)
    private enum APIEndpoint {
        static let workouts = "/workouts"
        static let exercises = "/exercises"
        static func workoutDetail(id: String) -> String { return "/workouts/\(id)" }
        // static let updateUserLocation = "/profile/location" // Placeholder
    }

    // MARK: - Protocol Implementation

    // Save a workout, expect the saved record back
    func saveWorkout(workoutData: InsertUserExerciseRequest) async throws -> UserExerciseRecord {
        print("WorkoutService: Saving workout...")
        let savedRecord: UserExerciseRecord = try await networkClient.performRequest(
            endpointPath: APIEndpoint.workouts,
            method: "POST",
            body: workoutData
        )
        print("WorkoutService: Save workout successful. ID: \(savedRecord.id)")
        return savedRecord
    }

    // Fetch workout history with pagination
    func fetchWorkoutHistory(page: Int, pageSize: Int) async throws -> PaginatedUserExerciseResponse {
        print("WorkoutService: Fetching workout history (page: \(page), size: \(pageSize))...")
        let queryParams = [
            "page": String(page),
            "pageSize": String(pageSize)
        ]
        let response: PaginatedUserExerciseResponse = try await networkClient.performRequest(
            endpointPath: APIEndpoint.workouts,
            method: "GET",
            queryParams: queryParams
        )
        print("WorkoutService: Fetched \(response.items.count) history items for page \(response.currentPage)")
        return response
    }

    // Fetch list of available exercises
    func getExercises() async throws -> [Exercise] {
        print("WorkoutService: Fetching exercises...")
        let response: [Exercise] = try await networkClient.performRequest(
            endpointPath: APIEndpoint.exercises,
            method: "GET"
        )
        print("WorkoutService: Fetched \(response.count) exercises.")
        return response
    }

    // Fetch a single workout by its ID
    func getWorkoutById(id: String) async throws -> UserExerciseRecord {
        print("WorkoutService: Fetching workout with ID: \(id)")
        let endpointPath = APIEndpoint.workoutDetail(id: id)
        let response: UserExerciseRecord = try await networkClient.performRequest(
            endpointPath: endpointPath,
            method: "GET"
        )
        print("WorkoutService: Fetched workout ID \(response.id)")
        return response
    }

    // TODO: Implement other methods from Android WorkoutApiService
    // func updateUserLocation(location: LocationUpdateRequest) async throws -> Void

    // MARK: - Protocol Stubs (Implement Logic)

    func saveWorkout(result: InsertUserExerciseRequest, authToken: String) async throws -> Void {
        // TODO: Implement actual API call using networkClient
        print("WorkoutService: Saving workout...")
        // Example: Replace with actual network call
        // Note: Auth token is added automatically by performRequestNoContent if needed
        // try await networkClient.performRequestNoContent(
        //     endpointPath: "/workouts", // Adjust endpoint
        //     method: "POST",
        //     body: result
        // )
        // For now, do nothing
        print("WorkoutService: Placeholder - Workout save skipped.")
    }

    func fetchWorkoutHistory(authToken: String) async throws -> [UserExerciseRecord] {
        // TODO: Implement actual API call using networkClient
        print("WorkoutService: Fetching workout history...")
        // Example: Replace with actual network call
        // Note: Auth token is added automatically by performRequest if needed
        // let history: [UserExerciseRecord] = try await networkClient.performRequest(
        //     endpointPath: "/workouts/history", // Adjust endpoint
        //     method: "GET"
        // )
        // return history
        return [] // Placeholder
    }
}

// Note: Relies on aligned models: InsertUserExerciseRequest, UserExerciseRecord,
// PaginatedUserExerciseResponse, Exercise.
// APIError moved to NetworkClient.swift 