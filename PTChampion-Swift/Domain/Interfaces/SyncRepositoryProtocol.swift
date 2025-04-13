import Foundation

// Defines the contract for synchronizing local data with the backend.
protocol SyncRepositoryProtocol {
    // Performs the data synchronization process.
    // This involves sending local changes (e.g., unsynced exercises) 
    // and receiving server updates since the last sync.
    // Takes the device ID and potentially requires access to local data sources.
    func syncUserData(deviceId: String) async throws -> SyncResponse
    
    // Retrieves the timestamp of the last successful sync.
    func getLastSyncTimestamp() async -> String // Or Date?
    
    // Stores the timestamp of the latest successful sync.
    func saveLastSyncTimestamp(timestamp: String) async // Or Date?
} 