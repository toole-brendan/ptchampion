import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: String // Assuming String ID based on mock, adjust if Int from backend
    let email: String
    let firstName: String?
    let lastName: String?
    let profilePictureUrl: String?
    // Add other user fields as needed from your API spec (e.g., registration date, roles)
    
    // Helper computed property to get full name
    var fullName: String {
        if let first = firstName, let last = lastName {
            return "\(first) \(last)"
        } else if let first = firstName {
            return first
        } else if let last = lastName {
            return last
        } else {
            return email
        }
    }
} 