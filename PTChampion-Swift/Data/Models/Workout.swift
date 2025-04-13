import Foundation

// Matches the backend response for a created/fetched workout
struct WorkoutResponse: Codable, Identifiable {
    let id: Int
    let userId: Int
    let exerciseId: Int
    let startTime: Date
    let endTime: Date
    let reps: Int?
    let durationSeconds: Int?
    let formScore: Double?
    let grade: String?
    let createdAt: Date
    let exerciseName: String? // Included from backend query

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case exerciseId = "exercise_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case reps
        case durationSeconds = "duration_seconds"
        case formScore = "form_score"
        case grade
        case createdAt = "created_at"
        case exerciseName = "exercise_name" // Ensure backend sends this
    }
}

// Matches the request body for POST /api/v1/workouts
struct SaveWorkoutRequest: Codable {
    let exerciseId: Int
    let startTime: Date
    let endTime: Date
    let reps: Int?
    let durationSeconds: Int?
    let formScore: Double?
    let grade: String? // e.g., "PENDING"

    // Mapping snake_case keys for encoding
    enum CodingKeys: String, CodingKey {
        case exerciseId = "exercise_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case reps
        case durationSeconds = "duration_seconds"
        case formScore = "form_score"
        case grade
    }
} 