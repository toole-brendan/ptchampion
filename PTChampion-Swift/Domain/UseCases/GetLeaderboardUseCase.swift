import Foundation

// Use case for retrieving leaderboard data.
class GetLeaderboardUseCase {
    // Depend on the repository protocol, not the concrete implementation.
    private let leaderboardRepository: LeaderboardRepositoryProtocol
    
    // Inject the repository dependency.
    init(leaderboardRepository: LeaderboardRepositoryProtocol) {
        self.leaderboardRepository = leaderboardRepository
    }
    
    // Executes the operation to fetch the global leaderboard.
    func executeGlobal() async throws -> [LeaderboardEntry] {
        return try await leaderboardRepository.getGlobalLeaderboard()
    }
    
    // Executes the operation to fetch the local leaderboard based on location.
    func executeLocal(latitude: Double, longitude: Double, radiusMiles: Int = 10) async throws -> [LeaderboardEntry] {
        return try await leaderboardRepository.getLocalLeaderboard(
            latitude: latitude,
            longitude: longitude,
            radiusMiles: radiusMiles
        )
    }
} 