import Foundation

// Represents the request body for the /sync endpoint
struct SyncRequest: Codable {
    let deviceId: String
    let lastSyncTimestamp: String // ISO 8601 format string
    let data: SyncData? // Optional data payload containing updates
} 