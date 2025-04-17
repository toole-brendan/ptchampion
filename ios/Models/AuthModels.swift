import Foundation

// MARK: - Request Payloads

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct RegistrationRequest: Codable {
    let username: String
    let password: String
    let displayName: String?
    let profilePictureUrl: String?
    let location: String?
    // Latitude/Longitude could be added if needed for registration

    enum CodingKeys: String, CodingKey {
        case username
        case password
        case displayName = "display_name"
        case profilePictureUrl = "profile_picture_url"
        case location
    }
}

// MARK: - User Model (Aligned with shared/schema.ts)

struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let displayName: String?
    let profilePictureUrl: String?
    let location: String?
    let latitude: String? // Store as String, convert if needed (matching schema 'decimal')
    let longitude: String?
    let lastSyncedAt: Date? // Optional, assuming Date decoding strategy is set
    let createdAt: Date? // Optional
    let updatedAt: Date? // Optional

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case profilePictureUrl = "profile_picture_url"
        case location
        case latitude
        case longitude
        case lastSyncedAt = "last_synced_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Response Payloads

struct AuthResponse: Codable {
    let token: String
    let user: User
}

// MARK: - Error Handling

struct APIErrorResponse: Codable, Error {
    let message: String
    let code: String? // Optional error code from backend

    // Example: Conform to LocalizedError for better display
    var errorDescription: String? {
        return message
    }
}

// Generic wrapper for API responses, might be useful later
struct APIResponse<T: Codable>: Codable {
    let data: T?
    let error: APIErrorResponse?
} 