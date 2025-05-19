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
    private let treatNoDataAsEmpty = true    // NEW

    init(networkClient: NetworkClient? = nil, useMockData: Bool = false) {
        self.networkClient = networkClient
        self.useMockData = useMockData
        logger.debug("LeaderboardService initialized \(self.instanceId) (useMockData: \(useMockData))")
    }

    // MARK: - Protocol Implementation

    func fetchGlobalLeaderboard(authToken: String, timeFrame: String = "weekly", exerciseType: String) async throws -> [LeaderboardEntryView] {
        print("🔍 LeaderboardService[\(instanceId)]: Fetching global leaderboard for timeFrame: \(timeFrame), exerciseType: \(exerciseType)...")
        logger.debug("Fetching global leaderboard for timeFrame: \(timeFrame), exerciseType: \(exerciseType)...")
        
        if useMockData {
            print("🔍 LeaderboardService[\(instanceId)]: Using mock data (useMockData=true)")
            logger.debug("Using mock data for global leaderboard")
            return []
        }
        
        do {
            let endpointPath: String
            var queryParams = ["time_frame": timeFrame]

            if exerciseType == "aggregate_overall" {
                endpointPath = "/leaderboards/global/aggregate"
            } else {
                endpointPath = "/leaderboards/global/exercise/\(exerciseType)"
            }
            
            print("🔍 LeaderboardService[\(instanceId)]: Making API call to \(endpointPath) with params: \(queryParams)")
            
            guard let client = networkClient else {
                logger.info("No NetworkClient – returning empty array")
                return []              // ← KEY CHANGE
            }
            
            print("🔍 LeaderboardService[\(instanceId)]: NetworkClient available, making real API call")
            print("🔍 LeaderboardService[\(instanceId)]: About to call client.performRequest")
            let backendEntries: [GlobalLeaderboardEntry] = try await client.performRequest(
                endpointPath: endpointPath,
                method: "GET",
                queryParams: queryParams,
                body: nil
            )
            
            print("🔍 LeaderboardService[\(instanceId)]: API call completed successfully")
            
            // Convert backend entries to the format expected by the UI
            logger.debug("Fetched \(backendEntries.count) global leaderboard entries from server")
            print("🔍 LeaderboardService[\(instanceId)]: Fetched \(backendEntries.count) entries from server")
            
            // Convert from backend model to view model
            var convertedEntries: [LeaderboardEntryView] = []
            for (index, entry) in backendEntries.enumerated() {
                let rank = entry.rank ?? (index + 1) // Use provided rank or index+1
                convertedEntries.append(LeaderboardEntryView(
                    id: "global-\(entry.id)",
                    rank: rank,
                    userId: "\(entry.id)",
                    name: entry.displayName ?? entry.username,
                    score: entry.score
                ))
            }
            
            logger.debug("Converted \(convertedEntries.count) global entries to view model format")
            print("🔍 LeaderboardService[\(instanceId)]: Returning \(convertedEntries.count) converted entries")
            return convertedEntries
        } catch {
            logger.error("Error fetching global leaderboard: \(error.localizedDescription)")
            print("🔍 LeaderboardService[\(instanceId)]: ERROR: \(error.localizedDescription)")
            
            if treatNoDataAsEmpty {
                logger.info("No leaderboard rows currently – propagating empty array")
                return []
            } else {
                throw error                          // let VM decide
            }
        }
    }

    func fetchLocalLeaderboard(latitude: Double, longitude: Double, radiusMiles: Int, authToken: String, exerciseType: String, timeFrame: String) async throws -> [LeaderboardEntryView] {
        logger.debug("Fetching local leaderboard near \(latitude), \(longitude) with radius \(radiusMiles) miles, exercise: \(exerciseType), timeframe: \(timeFrame)")
        
        if useMockData {
            logger.debug("Using mock data for local leaderboard")
            return []
        }
        
        do {
            let radiusMeters = Double(radiusMiles) * 1609.34
            let endpointPath: String
            // Query parameters common to both local aggregate and specific exercise local
            var queryParams = [
                "latitude": String(latitude),
                "longitude": String(longitude),
                "radius_meters": String(radiusMeters),
                "time_frame": timeFrame
            ]

            if exerciseType == "aggregate_overall" {
                endpointPath = "/leaderboards/local/aggregate"
                // No exercise_type query param needed for aggregate path
            } else {
                endpointPath = "/leaderboards/local/exercise/\(exerciseType)"
                // No exercise_type query param needed as it's in the path
            }
            
            print("🔍 LeaderboardService[\(instanceId)]: Making API call to \(endpointPath) with params: \(queryParams)")

            guard let client = networkClient else {
                logger.info("No NetworkClient – returning empty array")
                return []              // ← KEY CHANGE
            }
            
            let backendEntries: [LocalLeaderboardEntry] = try await client.performRequest(
                endpointPath: endpointPath,
                method: "GET",
                queryParams: queryParams,
                body: nil
            )
            
            // Convert backend entries to the format expected by the UI
            logger.debug("Fetched \(backendEntries.count) local leaderboard entries from server")
            
            // Convert from backend model to view model
            var convertedEntries: [LeaderboardEntryView] = []
            for (index, entry) in backendEntries.enumerated() {
                let rank = entry.rank ?? (index + 1) // Use provided rank or index+1
                convertedEntries.append(LeaderboardEntryView(
                    id: "local-\(entry.id)",
                    rank: rank,
                    userId: "\(entry.id)",
                    name: entry.displayName ?? entry.username, 
                    score: entry.score
                ))
            }
            
            logger.debug("Converted \(convertedEntries.count) local entries to view model format")
            return convertedEntries
        } catch {
            logger.error("Error fetching local leaderboard: \(error.localizedDescription)")
            if treatNoDataAsEmpty {
                logger.info("No leaderboard rows currently – propagating empty array")
                return []
            } else {
                throw error                          // let VM decide
            }
        }
    }
    
    // MARK: - Mock Data Helpers
    
    private func generateMockLeaderboardEntries(count: Int, isLocal: Bool) -> [LeaderboardEntryView] {
        var entries: [LeaderboardEntryView] = []
        
        for i in 1...count {
            let entry = LeaderboardEntryView(
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
                endpointPath: "/leaderboards/local",
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

        // let endpoint = APIEndpoint.globalLeaderboard(exerciseType: exerciseType) // Commented out as it's unused with the temporary mock data return
        
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