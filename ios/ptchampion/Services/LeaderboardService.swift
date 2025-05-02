import Foundation
import CoreLocation

// Protocol defining the leaderboard service operations
/* REMOVED: This protocol should be defined in its own file (e.g., LeaderboardServiceProtocol.swift)
protocol LeaderboardServiceProtocol {
    func getLocalLeaderboard(exerciseId: Int, latitude: Double, longitude: Double, radiusMeters: Double?) async throws -> [LocalLeaderboardEntry]
    func getGlobalLeaderboard(exerciseType: String, limit: Int?) async throws -> [GlobalLeaderboardEntry]
}
*/

// Implementation using the shared NetworkClient
// Make sure this class conforms to the protocol defined elsewhere
class LeaderboardService: LeaderboardServiceProtocol {

    private let networkClient: NetworkClient

    init(networkClient: NetworkClient = NetworkClient()) {
        self.networkClient = networkClient
    }

    // MARK: - API Endpoints (Paths only)
    private enum APIEndpoint {
        static let localLeaderboard = "/leaderboards/local"
        // Path parameter needs to be interpolated for global
        static func globalLeaderboard(exerciseType: String) -> String {
             return "/leaderboard/\(exerciseType)" // Matches Android path
        }
    }

    // MARK: - Protocol Implementation

    func fetchGlobalLeaderboard(authToken: String) async throws -> [LeaderboardEntry] {
        print("LeaderboardService: Fetching global leaderboard...")
        // Implementation using networkClient
        // For now returning empty array, will be implemented soon
        return []
    }

    func fetchLocalLeaderboard(latitude: Double, longitude: Double, radiusMiles: Int, authToken: String) async throws -> [LeaderboardEntry] {
        print("LeaderboardService: Fetching local leaderboard (lat: \(latitude), lon: \(longitude), radius: \(radiusMiles))...")
        let queryParams = [
            "latitude": String(latitude),
            "longitude": String(longitude),
            "radiusMiles": String(radiusMiles)
        ]
        
        // Implementation using networkClient
        // For now returning empty array, will be implemented soon
        return []
    }
    
    // MARK: - Additional Helper Methods (Not part of protocol)
    
    // These are helper methods that will be used by the protocol methods above
    // Future implementation for more specific leaderboard functionality
    
    func getLocalLeaderboard(
        exerciseId: Int,
        latitude: Double,
        longitude: Double,
        radiusMeters: Double?
    ) async throws -> [LocalLeaderboardEntry] {
        
        print("LeaderboardService: Fetching local leaderboard for exercise \(exerciseId)")
        var queryParams: [String: String] = [
            "exercise_id": String(exerciseId),
            "latitude": String(latitude),
            "longitude": String(longitude)
        ]
        
        if let radius = radiusMeters {
            queryParams["radius_meters"] = String(radius)
        }

        let response: [LocalLeaderboardEntry] = try await networkClient.performRequest(
            endpointPath: APIEndpoint.localLeaderboard,
            method: "GET",
            queryParams: queryParams
        )
        print("LeaderboardService: Fetched \(response.count) local leaderboard entries.")
        return response
    }

    func getGlobalLeaderboard(
        exerciseType: String,
        limit: Int?
    ) async throws -> [GlobalLeaderboardEntry] {
        
        print("LeaderboardService: Fetching global leaderboard for \(exerciseType)")
        let endpointPath = APIEndpoint.globalLeaderboard(exerciseType: exerciseType)
        var queryParams: [String: String]? = nil
        
        if let limit = limit {
            queryParams = ["limit": String(limit)]
        }

        let response: [GlobalLeaderboardEntry] = try await networkClient.performRequest(
            endpointPath: endpointPath,
            method: "GET",
            queryParams: queryParams
        )
        print("LeaderboardService: Fetched \(response.count) global leaderboard entries.")
        return response
    }
}

// Assuming APIError and APIErrorResponse are accessible 