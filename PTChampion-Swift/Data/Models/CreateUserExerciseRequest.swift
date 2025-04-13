import Foundation

// Represents the data sent to the backend when creating a new user exercise record
struct CreateUserExerciseRequest: Codable {
    let exerciseId: Int
    let type: String // Consider making this an enum if types are fixed
    let repetitions: Int?
    let formScore: Int? // Consider Double for more granularity
    let timeInSeconds: Int?
    let distance: Double?
    let grade: Int // Consider String or enum for grade representation
    let metadata: [String: String]? // Use Codable dictionary for flexible metadata
    let deviceId: String? // Optional identifier for the device logging the exercise
    let syncStatus: String? // Optional status, consider enum (e.g., "pending", "synced")
    // Add createdAt or recordedAt timestamp if needed, managed locally
    // let recordedAt: Date?
} 