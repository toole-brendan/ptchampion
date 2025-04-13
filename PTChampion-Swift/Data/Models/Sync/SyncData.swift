import Foundation

// Represents the data payload within a SyncRequest
struct SyncData: Codable {
    // Contains arrays of local data created/modified since the last sync
    let userExercises: [CreateUserExerciseRequest]? // Unsynced exercises
    let profile: UpdateProfileRequest? // Pending profile updates (if applicable)
    // Add other data types that need syncing here (e.g., settings)
} 