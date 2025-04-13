import Foundation

// Represents the data payload within a SyncResponse
struct SyncResponseData: Codable {
    // Contains arrays of data fetched from the server
    let userExercises: [UserExercise]? // Exercises updated on the server
    let profile: User? // Updated user profile from the server
    // Add other data types synced from the server here
} 