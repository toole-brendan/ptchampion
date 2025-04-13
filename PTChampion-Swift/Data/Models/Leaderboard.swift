import Foundation

// Represents a single entry in a leaderboard
struct LeaderboardEntry: Codable, Identifiable {
    let rank: Int
    let userId: Int
    let username: String
    let score: Int // Assuming score is reps or inverse time
    let distance: Double? // Optional distance for local leaderboards

    // Conform to identifiable using rank or a combination if rank isn't unique across pages
    var id: Int { rank }

    enum CodingKeys: String, CodingKey {
        case rank
        case userId = "user_id"
        case username
        case score // Ensure backend sends 'score'
        case distance // Optional key for local leaderboards
    }
}

// Represents the paginated response for leaderboard endpoints
struct LeaderboardResponse: Codable {
    let leaderboard: [LeaderboardEntry]
    let totalEntries: Int
    let page: Int
    let pageSize: Int

    enum CodingKeys: String, CodingKey {
        case leaderboard
        case totalEntries = "total_entries"
        case page
        case pageSize = "page_size"
    }
} 