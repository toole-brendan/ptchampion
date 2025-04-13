import Foundation

// Represents the response from the API health check endpoint
struct HealthResponse: Codable {
    let status: String
    let timestamp: String // Consider using Date with appropriate decoding strategy
    let version: String
} 