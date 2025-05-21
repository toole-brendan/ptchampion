import Foundation

// Implementation of workout service functionality using the shared NetworkClient
class WorkoutService {

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
        static func exerciseDetail(id: Int) -> String { return "/exercises/\(id)" }
        // static let updateUserLocation = "/profile/location" // Placeholder
    }
    
    // MARK: - API Request Models
    
    // Codable struct for the exercise API request
    private struct ExerciseAPIRequest: Encodable {
        let exercise_type: String
        let timestamp: String
        let duration: Double
        let rep_count: Int?
        let score: Double?
        let form_quality: Double?
        let distance_meters: Double?
        let is_public: Bool
        let idempotency_key: String?
        
        init(exercise: LogExerciseRequest, isPublic: Bool, idempotencyKey: String?) {
            self.exercise_type = exercise.exerciseType
            self.timestamp = ISO8601DateFormatter().string(from: exercise.timestamp)
            self.duration = exercise.duration
            self.rep_count = exercise.repCount
            self.score = exercise.score
            self.form_quality = exercise.formQuality
            self.distance_meters = exercise.distanceMeters
            self.is_public = isPublic
            self.idempotency_key = idempotencyKey ?? exercise.idempotencyKey
        }
    }

    // MARK: - Core API Methods

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

    // MARK: - Former Protocol Methods
    
    // Simple wrapper for fetchWorkoutHistory without pagination
    func fetchWorkoutHistory(authToken: String) async throws -> [UserExerciseRecord] {
        // Fetch first page of history (or all, if API returns everything)
        let response = try await fetchWorkoutHistory(page: 1, pageSize: 1000)
        return response.items
    }

    // Simplified saveWorkout matching the previous protocol signature
    func saveWorkout(result: InsertUserExerciseRequest, authToken: String) async throws {
        // Reuse the existing saveWorkout implementation and ignore its return
        _ = try await saveWorkout(workoutData: result)
    }

    // MARK: - Offline Sync Support Methods
    
    /// Log an exercise to the server
    func logExercise(_ exercise: LogExerciseRequest, isPublic: Bool, idempotencyKey: String? = nil) async throws -> LogExerciseResponse {
        // Create a proper Encodable request object
        let params = ExerciseAPIRequest(
            exercise: exercise,
            isPublic: isPublic,
            idempotencyKey: idempotencyKey
        )
        
        // Make the network request
        return try await networkClient.performRequest(
            endpointPath: "/exercises/log",
            method: "POST",
            body: params
        )
    }
    
    /// Update an existing exercise on the server
    func updateExercise(id: Int, data: LogExerciseRequest, isPublic: Bool) async throws -> LogExerciseResponse {
        // Create a proper Encodable request object
        let params = ExerciseAPIRequest(
            exercise: data,
            isPublic: isPublic,
            idempotencyKey: data.idempotencyKey
        )
        
        // Make the network request
        return try await networkClient.performRequest(
            endpointPath: "/exercises/\(id)",
            method: "PUT",
            body: params
        )
    }
    
    /// Delete an exercise from the server
    func deleteExercise(id: Int) async throws {
        // Make the delete request
        try await networkClient.performRequestNoContent(
            endpointPath: "/exercises/\(id)",
            method: "DELETE"
        )
    }
    
    /// Get workout by server ID for conflict checking
    func getWorkoutById(serverId: Int) async throws -> ServerWorkoutModel {
        // Make the network request to get workout details
        return try await networkClient.performRequest(
            endpointPath: APIEndpoint.exerciseDetail(id: serverId),
            method: "GET"
        )
    }
}

// Note: Relies on aligned models: InsertUserExerciseRequest, UserExerciseRecord,
// PaginatedUserExerciseResponse, Exercise.
// APIError moved to NetworkClient.swift 