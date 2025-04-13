import Foundation

// Represents the response from login/registration endpoints
struct AuthResponse: Codable {
    let token: String
    let user: User // Assumes User struct is available (defined in User.swift)
    
    // No need for custom coding keys since our property names already match the backend's expected format
} 