import Foundation

/// Protocol defining workout service operations
protocol WorkoutServiceProtocol {
    func fetchWorkoutHistory() async throws -> [WorkoutHistory]
    func saveWorkout(_ workout: WorkoutHistory) async throws
    func deleteWorkout(id: String) async throws
    func fetchLeaderboard() async throws -> [LeaderboardEntry]
}

/// Implementation of WorkoutServiceProtocol using NetworkService
class WorkoutService: WorkoutServiceProtocol {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService.shared) {
        self.networkService = networkService
    }
    
    /// Fetch workout history from remote API
    /// - Returns: Array of workout history items
    func fetchWorkoutHistory() async throws -> [WorkoutHistory] {
        let response: WorkoutHistoryResponse = try await networkService.request(
            "/workouts/history",
            requiresAuth: true
        )
        return response.workouts
    }
    
    /// Save a workout to remote API
    /// - Parameter workout: Workout to save
    func saveWorkout(_ workout: WorkoutHistory) async throws {
        let request = SaveWorkoutRequest(
            exerciseType: workout.exerciseType,
            reps: workout.reps,
            distance: workout.distance,
            duration: workout.duration,
            date: workout.date
        )
        
        let _: EmptyResponse = try await networkService.request(
            "/workouts/save",
            method: .post,
            body: request,
            requiresAuth: true
        )
    }
    
    /// Delete a workout by ID
    /// - Parameter id: ID of workout to delete
    func deleteWorkout(id: String) async throws {
        let _: EmptyResponse = try await networkService.request(
            "/workouts/\(id)",
            method: .delete,
            requiresAuth: true
        )
    }
    
    /// Fetch leaderboard data
    /// - Returns: Array of leaderboard entries
    func fetchLeaderboard() async throws -> [LeaderboardEntry] {
        let response: LeaderboardResponse = try await networkService.request(
            "/leaderboard",
            requiresAuth: true
        )
        return response.entries
    }
}

// MARK: - Request/Response Models

/// Request model for saving a workout
struct SaveWorkoutRequest: Encodable {
    let exerciseType: String
    let reps: Int?
    let distance: Double?
    let duration: TimeInterval
    let date: Date
}

/// Response model for workout history
struct WorkoutHistoryResponse: Decodable {
    let workouts: [WorkoutHistory]
}

/// Response model for leaderboard
struct LeaderboardResponse: Decodable {
    let entries: [LeaderboardEntry]
}

// MARK: - Domain Models (if not already defined elsewhere)

/// Workout history item
struct LeaderboardEntry: Identifiable, Decodable {
    let id: String
    let userId: String
    let userName: String
    let avatarUrl: String?
    let score: Int
    let rank: Int
    let isCurrentUser: Bool
}

// Workout history model is already defined in WorkoutHistoryViewModel.swift 