import Foundation
import Combine
import CoreLocation // For CLLocationCoordinate2D

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