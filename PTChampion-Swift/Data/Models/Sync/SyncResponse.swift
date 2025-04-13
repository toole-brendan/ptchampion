import Foundation

// Represents the response body from the /sync endpoint
struct SyncResponse: Codable {
    let success: Bool
    let timestamp: String // ISO 8601 format string (timestamp of this sync operation)
    let data: SyncResponseData? // Optional payload with data from the server
    let conflicts: [UserExercise]? // Optional list of conflicts detected by the server
} 