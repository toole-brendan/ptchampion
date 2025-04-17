import Foundation

// MARK: - Request Payloads

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegistrationRequest: Codable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    // Add any other required registration fields based on API spec
}

// MARK: - Response Payloads

struct AuthResponse: Codable {
    let token: String
    // Include user object if API returns it on login/register, otherwise fetch separately
    // let user: User?
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