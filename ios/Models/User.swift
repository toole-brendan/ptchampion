import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: String // Assuming String ID based on mock, adjust if Int from backend
    let email: String
    let firstName: String?
    let lastName: String?
    // Add other user fields as needed from your API spec (e.g., registration date, roles)
} 