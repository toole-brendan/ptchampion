import Foundation

// Represents the logged-in user data (received after login/registration or profile fetch)
struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let username: String
    let createdAt: Date
    let latitude: Double?
    let longitude: Double?
    let displayName: String?
    let profilePictureUrl: String?
    let location: String?
    let lastSyncedAt: Date?
    let updatedAt: Date?
    // Add other fields if returned by your backend (e.g., firstName, lastName)

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case createdAt
        case latitude
        case longitude
        case displayName
        case profilePictureUrl
        case location
        case lastSyncedAt
        case updatedAt
    }
}

extension User {
    var hasLocation: Bool {
        return latitude != nil && longitude != nil
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdAt)
    }
}