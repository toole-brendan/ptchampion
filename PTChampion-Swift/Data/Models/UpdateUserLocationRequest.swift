import Foundation

// Model for updating user location (matches backend request)
struct UpdateUserLocationRequest: Codable {
    let latitude: Double
    let longitude: Double
    
    // No need for custom coding keys since our property names already match the backend's expected format
} 