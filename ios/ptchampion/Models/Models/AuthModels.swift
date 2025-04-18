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

// MARK: - Response Payloads

struct AuthResponse: Codable {
    let token: String
    let user: User
}

// Generic API Response wrapper (Optional - Use if your API consistently wraps responses)
// If used, ensure AuthResponse above is nested within this or handled appropriately.
// struct APIResponse<T: Codable>: Codable {
// ... existing code ...
// } 