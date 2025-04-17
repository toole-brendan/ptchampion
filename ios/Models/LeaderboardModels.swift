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