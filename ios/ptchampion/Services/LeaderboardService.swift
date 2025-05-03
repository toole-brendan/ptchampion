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
    
    // Flag to control whether real API calls are made or mock data is used
    private let useMockData: Bool

    init(networkClient: NetworkClient? = nil, useMockData: Bool = false) {
        self.networkClient = networkClient
        self.useMockData = useMockData
        logger.debug("LeaderboardService initialized \(self.instanceId) (useMockData: \(useMockData))")
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

    func fetchGlobalLeaderboard(authToken: String, timeFrame: String = "weekly") async throws -> [LeaderboardEntry] {
        logger.debug("Fetching global leaderboard for timeFrame: \(timeFrame)...")
        
        // If forced to use mock data or real API calls are disabled
        if useMockData {
            logger.debug("Using mock data for global leaderboard")
            return generateMockLeaderboardEntries(count: 10, isLocal: false)
        }
        
        // Make the real API call
        do {
            let queryParams = ["time_frame": timeFrame]
            let endpoint = APIEndpoint.globalLeaderboard(exerciseType: "general")
            
            // If we have a network client, make the real API call
            if let client = networkClient {
                let backendEntries: [GlobalLeaderboardEntry] = try await client.performRequest(
                    endpointPath: endpoint,
                    method: "GET",
                    queryParams: queryParams,
                    body: nil
                )
                
                // Convert backend entries to the format expected by the UI
                logger.debug("Fetched \(backendEntries.count) global leaderboard entries from server")
                
                // Convert from backend model to view model
                var convertedEntries: [LeaderboardEntry] = []
                for (index, entry) in backendEntries.enumerated() {
                    let rank = entry.rank ?? (index + 1) // Use provided rank or index+1
                    convertedEntries.append(LeaderboardEntry.fromGlobalEntry(entry, rank: rank))
                }
                
                logger.debug("Converted \(convertedEntries.count) global entries to view model format")
                return convertedEntries
            } else {
                logger.error("NetworkClient not available, falling back to mock data")
                return generateMockLeaderboardEntries(count: 10, isLocal: false)
            }
        } catch {
            logger.error("Error fetching global leaderboard: \(error.localizedDescription)")
            throw error
        }
    }

    func fetchLocalLeaderboard(latitude: Double, longitude: Double, radiusMiles: Int, authToken: String) async throws -> [LeaderboardEntry] {
        logger.debug("Fetching local leaderboard near \(latitude), \(longitude) with radius \(radiusMiles) miles")
        
        // If forced to use mock data or real API calls are disabled
        if useMockData {
            logger.debug("Using mock data for local leaderboard")
            return generateMockLeaderboardEntries(count: 10, isLocal: true)
        }
        
        // Make the real API call
        do {
            // Convert miles to meters for the API
            let radiusMeters = Double(radiusMiles) * 1609.34
            
            let queryParams = [
                "latitude": String(latitude),
                "longitude": String(longitude),
                "radius_meters": String(radiusMeters)
            ]
            
            // If we have a network client, make the real API call
            if let client = networkClient {
                let backendEntries: [LocalLeaderboardEntry] = try await client.performRequest(
                    endpointPath: APIEndpoint.localLeaderboard,
                    method: "GET",
                    queryParams: queryParams,
                    body: nil
                )
                
                // Convert backend entries to the format expected by the UI
                logger.debug("Fetched \(backendEntries.count) local leaderboard entries from server")
                
                // Convert from backend model to view model
                var convertedEntries: [LeaderboardEntry] = []
                for (index, entry) in backendEntries.enumerated() {
                    let rank = entry.rank ?? (index + 1) // Use provided rank or index+1
                    convertedEntries.append(LeaderboardEntry.fromLocalEntry(entry, rank: rank))
                }
                
                logger.debug("Converted \(convertedEntries.count) local entries to view model format")
                return convertedEntries
            } else {
                logger.error("NetworkClient not available, falling back to mock data")
                return generateMockLeaderboardEntries(count: 10, isLocal: true)
            }
        } catch {
            logger.error("Error fetching local leaderboard: \(error.localizedDescription)")
            throw error
        }
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
        
        logger.debug("Generated \(entries.count) mock \(isLocal ? "local" : "global") entries")
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