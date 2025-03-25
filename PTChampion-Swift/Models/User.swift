import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let username: String
    var location: String?
    var latitude: Double?
    var longitude: Double?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case location
        case latitude
        case longitude
        case createdAt = "created_at"
    }
}

// Used for login requests
struct LoginCredentials: Codable {
    let username: String
    let password: String
}

// Used for registration requests
struct RegisterCredentials: Codable {
    let username: String
    let password: String
    var location: String?
    var latitude: Double?
    var longitude: Double?
}

// Used for location updates
struct LocationUpdate: Codable {
    let latitude: Double
    let longitude: Double
}