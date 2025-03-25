import Foundation

struct User: Identifiable, Codable {
    let id: Int
    let username: String
    let password: String?
    let displayName: String?
    let profilePictureUrl: String?
    let location: String?
    let latitude: Double?
    let longitude: Double?
    let deviceId: String?
    let lastSyncedAt: Date?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case password
        case displayName
        case profilePictureUrl
        case location
        case latitude
        case longitude
        case deviceId
        case lastSyncedAt
        case createdAt
        case updatedAt
    }
    
    init(id: Int, username: String, password: String? = nil, 
         displayName: String? = nil, profilePictureUrl: String? = nil, 
         location: String? = nil, latitude: Double? = nil, longitude: Double? = nil, 
         deviceId: String? = nil, lastSyncedAt: Date? = nil, 
         createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.username = username
        self.password = password
        self.displayName = displayName
        self.profilePictureUrl = profilePictureUrl
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.deviceId = deviceId
        self.lastSyncedAt = lastSyncedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension User {
    var hasLocation: Bool {
        return latitude != nil && longitude != nil
    }
    
    var formattedDate: String? {
        guard let createdAt = createdAt else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return formatter.string(from: createdAt)
    }
}