import Foundation
import Combine
import CoreLocation // For CLLocationCoordinate2D

// Protocol defining the interface for leaderboard data fetching
protocol LeaderboardServiceProtocol {

    // Fetches the global leaderboard
    func fetchGlobalLeaderboard(authToken: String) async throws -> [LeaderboardEntry]

    // Fetches the local leaderboard based on coordinates and radius
    func fetchLocalLeaderboard(latitude: Double,
                               longitude: Double,
                               radiusMiles: Int,
                               authToken: String) async throws -> [LeaderboardEntry]
} 