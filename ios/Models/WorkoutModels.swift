import Foundation

// Enum for different types of exercises tracked
// Ensure this matches backend expectations / OpenAPI spec
enum ExerciseType: String, Codable, CaseIterable {
    case pushups = "Push-ups" // Match WorkoutSelectionView names
    case situps = "Sit-ups"
    case pullups = "Pull-ups"
    case run = "Run"
    case unknown = "Unknown"

    init(displayName: String) {
        self = ExerciseType(rawValue: displayName) ?? .unknown
    }
}

// Represents the data to be saved for a completed workout session
struct WorkoutResultPayload: Codable {
    let exerciseType: String // Use rawValue of ExerciseType
    let startTime: Date
    let endTime: Date
    let durationSeconds: Int
    let repCount: Int? // Nullable for non-rep exercises like running
    let score: Int? // Optional calculated score
    // Add other relevant metrics: distance, average HR, form rating, etc.
    // let distanceMeters: Double?
    // let averageHeartRate: Int?
    // let formRating: Double?

    // CodingKeys to potentially match backend API field names
    // enum CodingKeys: String, CodingKey {
    //     case exerciseType = "exercise_type"
    //     case startTime = "start_time"
    //     case endTime = "end_time"
    //     case durationSeconds = "duration_seconds"
    //     case repCount = "rep_count"
    //     case score
    // }
}

// Represents a workout record fetched from the backend (e.g., for history)
struct WorkoutRecord: Codable, Identifiable {
    let id: String // Assuming backend provides a unique ID
    let userId: String // Assuming association with user
    let exerciseType: String
    let startTime: Date
    let endTime: Date
    let durationSeconds: Int
    let repCount: Int?
    let score: Int?
    // Add other fetched fields

    // Convert raw exerciseType string back to enum if needed
    var type: ExerciseType {
        ExerciseType(rawValue: exerciseType) ?? .unknown
    }

    // Example coding keys if backend names differ
    // enum CodingKeys: String, CodingKey {
    //     case id
    //     case userId = "user_id"
    //     case exerciseType = "exercise_type"
    //     case startTime = "start_time"
    //     case endTime = "end_time"
    //     case durationSeconds = "duration_seconds"
    //     case repCount = "rep_count"
    //     case score
    // }
} 