import Foundation

struct User: Identifiable, Codable {
    let id: Int
    let username: String
    let password: String?
    let latitude: Double?
    let longitude: Double?
    let deviceId: String?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case password
        case latitude
        case longitude
        case deviceId
        case createdAt
    }
    
    init(id: Int, username: String, password: String? = nil, latitude: Double? = nil, longitude: Double? = nil, deviceId: String? = nil, createdAt: Date? = nil) {
        self.id = id
        self.username = username
        self.password = password
        self.latitude = latitude
        self.longitude = longitude
        self.deviceId = deviceId
        self.createdAt = createdAt
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