import Foundation

// Defines the contract for fetching leaderboard data.
protocol LeaderboardRepositoryProtocol {
    // Fetches the global leaderboard entries.
    // TODO: Specify parameters if needed (e.g., exercise type, time period).
    func getGlobalLeaderboard() async throws -> [LeaderboardEntry]
    
    // Fetches leaderboard entries local to the given coordinates and radius.
    func getLocalLeaderboard(latitude: Double, longitude: Double, radiusMiles: Int) async throws -> [LeaderboardEntry]
} 