import Foundation
import CoreLocation
import os.log

// Setup logger
private let logger = Logger(subsystem: "com.ptchampion", category: "LeaderboardService")

// MARK: - Leaderboard Service Implementation
class LeaderboardService: LeaderboardServiceProtocol {

    private let networkClient: NetworkClient?
    // Add unique ID for identifying instances in logs
    private let instanceId = UUID().uuidString.prefix(6)

    init(networkClient: NetworkClient? = nil) {
        self.networkClient = networkClient
        logger.debug("LeaderboardService initialized \(self.instanceId)")
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
        logger.debug("Fetching global leaderboard...")
        
        // For initial testing, return mock data to prevent freezes
        return generateMockLeaderboardEntries(count: 10, isLocal: false)
    }

    func fetchLocalLeaderboard(latitude: Double, longitude: Double, radiusMiles: Int, authToken: String) async throws -> [LeaderboardEntry] {
        logger.debug("Fetching local leaderboard near \(latitude), \(longitude) with radius \(radiusMiles) miles")
       
        // For initial testing, return mock data to prevent freezes
        return generateMockLeaderboardEntries(count: 10, isLocal: true)
    }
    
    // MARK: - Mock Data Helpers
    
    private func generateMockLeaderboardEntries(count: Int, isLocal: Bool) -> [LeaderboardEntry] {
        var entries: [LeaderboardEntry] = []
        
        for i in 1...count {
            let entry = LeaderboardEntry(
                id: "entry-\(i)",
                rank: i,
                userId: "user-\(i)",
                name: isLocal ? "Local User \(i)" : "User \(i)",
                score: 1000 - (i * 30)
            )
            entries.append(entry)
        }
        
        return entries
    }
    
    // MARK: - Additional Helper Methods (For Future Implementation)
    
    func getLocalLeaderboard(
        exerciseId: Int,
        latitude: Double,
        longitude: Double,
        radiusMeters: Double?
    ) async throws -> [LocalLeaderboardEntry] {
        logger.debug("Fetching local leaderboard for exercise \(exerciseId)")
        var queryParams: [String: String] = [
            "exercise_id": String(exerciseId),
            "latitude": String(latitude),
            "longitude": String(longitude)
        ]
        
        if let radius = radiusMeters {
            queryParams["radius_meters"] = String(radius)
        }

        do {
            let response: [LocalLeaderboardEntry] = try await networkClient?.performRequest(
                endpointPath: APIEndpoint.localLeaderboard,
                method: "GET",
                queryParams: queryParams
            ) ?? []
            logger.debug("Fetched \(response.count) local leaderboard entries")
            return response
        } catch {
            logger.error("Failed to fetch local leaderboard: \(error.localizedDescription)")
            throw error
        }
    }

    func getGlobalLeaderboard(
        exerciseType: String,
        limit: Int? = nil
    ) async throws -> [GlobalLeaderboardEntry] {
        logger.debug("Fetching global leaderboard for \(exerciseType)")
        var queryParams: [String: String] = [:]
        
        if let limit = limit {
            queryParams["limit"] = String(limit)
        }

        let endpoint = APIEndpoint.globalLeaderboard(exerciseType: exerciseType)
        
        // TEMPORARY FIX: Return mock data instead of making API call
        logger.debug("USING MOCK DATA INSTEAD OF REAL API CALL")
        let mockEntries = (1...20).map { i in
            GlobalLeaderboardEntry(
                id: i,
                rank: i,
                username: "User \(i)",
                displayName: "User \(i)",
                profilePictureUrl: nil,
                score: 1000 - (i * 30)
            )
        }
        return mockEntries
        
        /* Original code, commented out temporarily
        do {
            let response: [GlobalLeaderboardEntry] = try await networkClient?.performRequest(
                endpointPath: endpoint,
                method: "GET",
                queryParams: queryParams
            ) ?? []
            logger.debug("Fetched \(response.count) global leaderboard entries")
            return response
        } catch {
            logger.error("Failed to fetch global leaderboard: \(error.localizedDescription)")
            throw error
        }
        */
    }
    
    deinit {
        logger.debug("LeaderboardService deinitializing \(self.instanceId)")
    }
}

// Assuming APIError and APIErrorResponse are accessible 