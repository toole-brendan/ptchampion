import Foundation
import Combine
import CoreLocation // For CLLocationCoordinate2D

/// Light-weight value used by the view-model and UI.
struct LeaderboardEntryView: Identifiable, Equatable {
    let id:       String        // unique: "global-<backendId>"
    let rank:     Int
    let userId:   String?       // optional – backend may omit
    let name:     String        // display name you show in the list
    let score:    Int           // points / reps / seconds – whatever your API returns
}

// Protocol defining the interface for leaderboard data fetching
protocol LeaderboardServiceProtocol {

    // Fetches the global leaderboard with optional time frame parameter
    func fetchGlobalLeaderboard(authToken: String, timeFrame: String, exerciseType: String) async throws -> [LeaderboardEntryView]

    // Fetches the local leaderboard based on coordinates and radius
    func fetchLocalLeaderboard(latitude: Double,
                               longitude: Double,
                               radiusMiles: Int,
                               authToken: String,
                               exerciseType: String,
                               timeFrame: String) async throws -> [LeaderboardEntryView]
} 