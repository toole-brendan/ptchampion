import Foundation

// Request body for updating the user's location
struct UpdateLocationRequest: Codable {
    let latitude: Double
    let longitude: Double
    // Add location name string if API supports it
    // let location: String?
}

// Response struct if the API returns user profile data after update
// If it just returns success (2xx No Content), this isn't needed.
// struct UserProfileResponse: Codable {
//    let user: User // Assuming User struct is defined elsewhere (e.g., AuthModels)
// } 