import Foundation

// Use AuthUserModel from User.swift
// No need for typealias since we're directly using the type

// MARK: - Request Payloads

// Renamed to avoid conflict with UnifiedNetworkService.LoginRequest
struct AuthLoginRequest: Codable {
    let email: String
    let password: String
}

struct RegistrationRequest: Codable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let username: String
    
    enum CodingKeys: String, CodingKey {
        case email
        case password
        case firstName = "first_name"
        case lastName = "last_name"
        case username
    }
    
    init(email: String, password: String, firstName: String, lastName: String, username: String) {
        self.email = email
        self.password = password
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
    }
}

// MARK: - Response Payloads

struct AuthResponse: Codable {
    let token: String
    let refreshToken: String
    let user: AuthUserModel
    
    enum CodingKeys: String, CodingKey {
        case token, user
        // Alternative keys that might be used by Azure backend
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode access token (supports both "token" and "access_token")
        token = try container.decodeIfPresent(String.self, forKey: .accessToken)
                ?? container.decode(String.self, forKey: .token)
        
        // Decode refresh token
        refreshToken = try container.decode(String.self, forKey: .refreshToken)
        
        user = try container.decode(AuthUserModel.self, forKey: .user)
    }
    
    // Add encode method to complete Codable conformance
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(token, forKey: .accessToken)
        try container.encode(refreshToken, forKey: .refreshToken)
        try container.encode(user, forKey: .user)
    }
    
    // Custom init for creating mock responses
    init(token: String, refreshToken: String, user: AuthUserModel) {
        self.token = token
        self.refreshToken = refreshToken
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