import Foundation

// Use the renamed AuthUserModel
typealias AuthUser = AuthUserModel

// MARK: - Request Payloads

// Renamed to avoid conflict with UnifiedNetworkService.LoginRequest
struct AuthLoginRequest: Codable {
    let username: String
    let password: String
}

struct RegistrationRequest: Codable {
    let username: String
    let password: String
    let displayName: String?
    let email: String
    let profilePictureUrl: String?
    let location: String?
    let latitude: Double?
    let longitude: Double?
    
    enum CodingKeys: String, CodingKey {
        case username
        case password
        case displayName = "display_name"
        case email
        case profilePictureUrl = "profile_picture_url"
        case location
        case latitude
        case longitude
    }
    
    // Initializer to create registration request from different inputs
    init(username: String, password: String, displayName: String? = nil, email: String? = nil, profilePictureUrl: String? = nil, location: String? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        self.username = username
        self.password = password
        self.displayName = displayName
        self.email = email ?? username // Fallback to username if email not provided
        self.profilePictureUrl = profilePictureUrl
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Response Payloads

struct AuthResponse: Codable {
    let token: String
    let user: AuthUser
    
    enum CodingKeys: String, CodingKey {
        case token, user
        // Alternative keys that might be used by Azure backend
        case accessToken = "access_token"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode token with different possible keys
        if let accessToken = try? container.decode(String.self, forKey: .accessToken) {
            token = accessToken
            print("AuthResponse: Using access_token field from response")
        } else {
            token = try container.decode(String.self, forKey: .token)
            print("AuthResponse: Using token field from response")
        }
        
        user = try container.decode(AuthUser.self, forKey: .user)
    }
    
    // Add encode method to complete Codable conformance
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(token, forKey: .token)
        try container.encode(user, forKey: .user)
    }
    
    // Custom init for creating mock responses
    init(token: String, user: AuthUser) {
        self.token = token
        self.user = user
    }
}

// MARK: - Error Payloads

struct ErrorEnvelope: Decodable {
    let message: String?
}

// Generic API Response wrapper (Optional - Use if your API consistently wraps responses)
// If used, ensure AuthResponse above is nested within this or handled appropriately.
// struct APIResponse<T: Codable>: Codable {
// ... existing code ...
// } 