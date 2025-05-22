import Foundation

// MARK: - LeaderboardView and UI Models

/// Represents a single entry in the leaderboard list view
struct LeaderboardEntryView: Identifiable, Equatable {
    let id: String        // unique: "global-<backendId>"
    let rank: Int
    let userId: String?   // optional – backend may omit
    let name: String      // display name you show in the list
    let score: Int        // points / reps / seconds – whatever your API returns
    let exerciseType: String? // Optional: type of exercise for context
    let location: String? // Optional: user's location for local leaderboards
    let distance: Double? // Optional: distance from current user (for local)
    let isPersonalBest: Bool? // Optional: whether this is the user's personal best
    let performanceChange: PerformanceChange? // Optional: change from previous ranking
    
    // Computed properties for display
    var displayValue: String {
        return "\(score)"
    }
    
    var displaySubtitle: String? {
        // Could be "reps", "minutes", etc. based on context
        return nil
    }
    
    var locationDescription: String? {
        if let distance = distance, distance > 0 {
            return String(format: "%.1f mi away", distance * 0.000621371) // Convert meters to miles
        }
        return location
    }
    
    var unit: String? {
        // Could be determined based on exercise type
        return nil
    }
}

// MARK: - Enum Types for Leaderboard Filters

/// Radius options for local leaderboards
enum LeaderboardRadius: Int, CaseIterable, Identifiable {
    case five = 5
    case ten = 10
    case twentyFive = 25
    case fifty = 50

    var id: Int { self.rawValue }
    var displayName: String { "\(self.rawValue) mi" }
}

/// Types of leaderboards (global vs local)
enum LeaderboardType: String, CaseIterable, Identifiable {
    case global = "Global"
    case local = "Local"
    var id: String { rawValue }
}

/// Exercise types for leaderboard filtering
enum LeaderboardExerciseType: String, CaseIterable, Identifiable {
    case overall, pushup, situp, pullup, running
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .overall: return "Overall"
        case .pushup: return "Push-ups"
        case .situp: return "Sit-ups"
        case .pullup: return "Pull-ups"
        case .running: return "Two-Mile Run"
        }
    }
}

/// Time period categories for leaderboard filtering
enum LeaderboardCategory: String, CaseIterable, Identifiable {
    case daily = "Daily", weekly = "Weekly", monthly = "Monthly", allTime = "All Time"
    var id: String { rawValue }
    var apiParameter: String {
        switch self {
        case .daily: return "daily"
        case .weekly: return "weekly"
        case .monthly: return "monthly"
        case .allTime: return "all_time"
        }
    }
}

/// Backend connection status for error handling
enum BackendStatus: Equatable {
    case unknown, connected, noActiveUsers, connectionFailed(String)
}

/// Performance change indicators for leaderboard entries
enum PerformanceChange: Equatable {
    case improved(positions: Int)
    case declined(positions: Int)
    case maintained
    
    var icon: String {
        switch self {
        case .improved: return "arrow.up.circle.fill"
        case .declined: return "arrow.down.circle.fill"
        case .maintained: return "minus.circle.fill"
        }
    }
}

// MARK: - API Models

/// Represents a single entry in a leaderboard as returned from backend
struct LeaderboardEntryModel: Codable, Identifiable {
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