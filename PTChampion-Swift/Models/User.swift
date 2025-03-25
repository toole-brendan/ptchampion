import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let password: String? // Only included for requests, never stored locally
    var firstName: String?
    var lastName: String?
    var email: String?
    var profileImageUrl: String?
    var latitude: Double?
    var longitude: Double?
    var overallScore: Int?
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case password
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case profileImageUrl = "profile_image_url"
        case latitude
        case longitude
        case overallScore = "overall_score"
        case createdAt = "created_at"
    }
    
    // Computed property to get full name
    var fullName: String {
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName) \(lastName)"
        } else if let firstName = firstName {
            return firstName
        } else if let lastName = lastName {
            return lastName
        } else {
            return username
        }
    }
    
    // Computed property to get initials for avatar
    var initials: String {
        if let firstName = firstName, let lastName = lastName {
            let firstInitial = String(firstName.prefix(1))
            let lastInitial = String(lastName.prefix(1))
            return "\(firstInitial)\(lastInitial)"
        } else if let firstName = firstName {
            return String(firstName.prefix(2))
        } else if let lastName = lastName {
            return String(lastName.prefix(2))
        } else {
            return String(username.prefix(2))
        }
    }
}

// Login credentials for API requests
struct LoginCredentials: Codable {
    let username: String
    let password: String
}

// Registration credentials for API requests
struct RegisterCredentials: Codable {
    let username: String
    let password: String
    let firstName: String?
    let lastName: String?
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case username
        case password
        case firstName = "first_name"
        case lastName = "last_name"
        case email
    }
}

// Location update model for API requests
struct LocationUpdate: Codable {
    let latitude: Double
    let longitude: Double
}

// Authentication state for persistence
struct AuthState: Codable {
    let user: User
    let isAuthenticated: Bool
    let lastLogin: Date
    
    static func empty() -> AuthState {
        return AuthState(
            user: User(id: 0, username: "", password: nil),
            isAuthenticated: false,
            lastLogin: Date()
        )
    }
}