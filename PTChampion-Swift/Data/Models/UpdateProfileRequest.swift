import Foundation

// Represents the data sent to update the user's profile
struct UpdateProfileRequest: Codable {
    // Only include fields that can be updated
    let displayName: String?
    let profilePictureUrl: String?
    let location: String? // Consider more structured location data if needed
    // Add other updatable profile fields (e.g., bio, preferences)
} 