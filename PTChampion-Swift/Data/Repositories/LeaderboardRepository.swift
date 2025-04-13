import Foundation

// Concrete implementation of the LeaderboardRepositoryProtocol using APIClient.
// Protocol is defined in Domain/Interfaces/LeaderboardRepositoryProtocol.swift
class LeaderboardRepository: LeaderboardRepositoryProtocol {
    // Use shared instance for consistency
    private let apiClient = APIClient.shared
    
    // Updated signature to match protocol
    func getGlobalLeaderboard() async throws -> [LeaderboardEntry] {
        // Call the corresponding APIClient method
        return try await apiClient.getGlobalLeaderboard()
    }
    
    // Updated signature to match protocol
    func getLocalLeaderboard(latitude: Double, longitude: Double, radiusMiles: Int) async throws -> [LeaderboardEntry] {
        // Call the corresponding APIClient method
        return try await apiClient.getLocalLeaderboard(
            latitude: latitude,
            longitude: longitude,
            radiusMiles: radiusMiles
        )
    }
}