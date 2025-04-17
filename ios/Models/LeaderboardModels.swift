import Foundation

// Represents a single entry in a leaderboard
struct LeaderboardEntry: Codable, Identifiable {
    let id: String // Unique ID for the entry or user ID if unique per user per board
    let rank: Int
    let userId: String? // Optional: If we need to link back to a user profile
    let name: String // User's display name
    let score: Int
    // Add other fields if provided by API (e.g., location, date achieved)

    // Example coding keys if backend names differ
    // enum CodingKeys: String, CodingKey {
    //     case id
    //     case rank
    //     case userId = "user_id"
    //     case name
    //     case score
    // }
}

// Optional: Define request structure if needed for API
// struct LeaderboardRequestParams: Codable {
//     let type: String // "global" or "local"
//     let latitude: Double?
//     let longitude: Double?
//     let radiusMiles: Int?
// }

// Represents an entry in the global leaderboard for a specific exercise type
struct GlobalLeaderboardEntry: Codable, Identifiable {
    // Assuming fields based on common leaderboards & schema
    // Adjust based on actual API response from /api/v1/leaderboard/{exerciseType}
    let id: Int // User ID likely serves as identifier here
    let rank: Int?
    let username: String
    let displayName: String?
    let profilePictureUrl: String?
    let score: Int // The user's score (e.g., reps, time) for this exercise
    // Add other relevant fields if provided (e.g., location, date)

    enum CodingKeys: String, CodingKey {
        case id // Assuming user ID
        case rank
        case username
        case displayName = "display_name"
        case profilePictureUrl = "profile_picture_url"
        case score // Assuming a generic 'score' field, could be reps, time, etc.
    }
}

// Represents an entry in the local leaderboard (based on location)
struct LocalLeaderboardEntry: Codable, Identifiable {
    // Assuming fields based on common leaderboards & schema
    // Adjust based on actual API response from /api/v1/leaderboards/local
    let id: Int // User ID
    let rank: Int?
    let username: String
    let displayName: String?
    let profilePictureUrl: String?
    let score: Int
    let distanceMeters: Double? // Distance from the requesting user
    let location: String?
    // Add other relevant fields

    enum CodingKeys: String, CodingKey {
        case id // Assuming user ID
        case rank
        case username
        case displayName = "display_name"
        case profilePictureUrl = "profile_picture_url"
        case score
        case distanceMeters = "distance_meters"
        case location
    }
} 