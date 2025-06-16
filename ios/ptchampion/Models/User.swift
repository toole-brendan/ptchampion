import Foundation

// Rename to avoid conflicts with other User definitions
public struct AuthUserModel: Identifiable, Codable, Equatable {
    public let id: String
    public var email: String
    public var username: String?
    public var firstName: String?
    public var lastName: String?
    public var profilePictureUrl: String?
    public var gender: String? // 'male' or 'female'
    public var dateOfBirth: Date? // For age calculation
    
    // Keys that correspond 1-to-1 with stored properties
    private enum CodingKeys: String, CodingKey {
        case id, email, username
        case firstName = "first_name"
        case lastName = "last_name"
        case profilePictureUrl = "profile_picture_url"
        case gender
        case dateOfBirth = "date_of_birth"
    }
    
    // Extra keys the backend may send
    private enum APIKeys: String, CodingKey {
        case username, displayName
    }
    
    // MARK: – Decodable
    public init(from decoder: Decoder) throws {
        let c   = try decoder.container(keyedBy: CodingKeys.self)
        let api = try decoder.container(keyedBy: APIKeys.self)
        
        // id may be Int or String
        if let intId = try? c.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try c.decode(String.self, forKey: .id)
        }
        
        // email: prefer `email`, fall back to legacy `username`
        email = try c.decodeIfPresent(String.self, forKey: .email)
              ?? api.decode(String.self, forKey: .username)
        
        // Try to get username from CodingKeys first, then from APIKeys if not present
        username = try? c.decode(String.self, forKey: .username)
        if username == nil {
            username = try? api.decode(String.self, forKey: .username)
        }
        
        // name can arrive as `displayName` or split fields
        if let display = try? api.decode(String.self, forKey: .displayName) {
            let parts = display.splitDisplayName()
            firstName = parts.firstName
            lastName  = parts.lastName
        } else {
            firstName = try? c.decode(String.self, forKey: .firstName)
            lastName  = try? c.decode(String.self, forKey: .lastName)
        }
        
        profilePictureUrl = try? c.decode(String.self, forKey: .profilePictureUrl)
        
        // Decode gender and dateOfBirth
        gender = try? c.decode(String.self, forKey: .gender)
        
        // Handle date_of_birth as string in ISO format
        if let dobString = try? c.decode(String.self, forKey: .dateOfBirth) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
            dateOfBirth = formatter.date(from: dobString)
        } else {
            dateOfBirth = nil
        }
    }
    
    // MARK: – Encodable
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,                forKey: .id)
        try c.encode(email,             forKey: .email)
        try c.encodeIfPresent(username, forKey: .username)
        try c.encodeIfPresent(firstName,forKey: .firstName)
        try c.encodeIfPresent(lastName, forKey: .lastName)
        try c.encodeIfPresent(profilePictureUrl, forKey: .profilePictureUrl)
        try c.encodeIfPresent(gender, forKey: .gender)
        
        // Encode dateOfBirth as string in ISO format
        if let dob = dateOfBirth {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
            let dobString = formatter.string(from: dob)
            try c.encode(dobString, forKey: .dateOfBirth)
        }
        // We deliberately **don't** encode `displayName`
    }
    
    // Convenience init you already had
    public init(id: String,
         email: String,
         username: String? = nil,
         firstName: String?,
         lastName: String?,
         profilePictureUrl: String?,
         gender: String? = nil,
         dateOfBirth: Date? = nil) {
        self.id = id
        self.email = email
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.profilePictureUrl = profilePictureUrl
        self.gender = gender
        self.dateOfBirth = dateOfBirth
    }
    
    public var fullName: String {
        switch (firstName, lastName) {
        case let (f?, l?): return "\(f) \(l)"
        case let (f?, nil): return f
        case let (nil, l?): return l
        default: return username ?? email
        }
    }
} 