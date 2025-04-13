import Foundation

// Concrete implementation of the SyncRepositoryProtocol.
class SyncRepository: SyncRepositoryProtocol {
    
    private let apiClient = APIClient.shared
    private let defaults = UserDefaults.standard
    private let lastSyncTimestampKey = "last_sync_timestamp"
    
    // Default timestamp for the very first sync
    private let defaultInitialTimestamp = "2000-01-01T00:00:00.000Z"
    
    func syncUserData(deviceId: String) async throws -> SyncResponse {
        // Delegate the actual network sync operation to the APIClient.
        // The APIClient itself calls internal placeholders for getting unsynced data
        // and saving the new timestamp, which we'll replace/remove eventually.
        // Ideally, this repository would coordinate fetching local data needed for the request
        // and processing the response (saving server data, updating local status).
        return try await apiClient.syncUserData(deviceId: deviceId)
    }
    
    func getLastSyncTimestamp() async -> String {
        // Retrieve the timestamp from UserDefaults.
        return defaults.string(forKey: lastSyncTimestampKey) ?? defaultInitialTimestamp
    }
    
    func saveLastSyncTimestamp(timestamp: String) async {
        // Save the timestamp to UserDefaults.
        defaults.set(timestamp, forKey: lastSyncTimestampKey)
        print("SyncRepository: Saved last sync timestamp - \(timestamp)")
    }
} 