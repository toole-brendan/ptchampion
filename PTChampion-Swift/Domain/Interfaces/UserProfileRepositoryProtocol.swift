import Foundation

// Defines the contract for user profile related operations.
protocol UserProfileRepositoryProtocol {
    // Updates the current user's location.
    // Returns the updated User object.
    func updateUserLocation(latitude: Double, longitude: Double) async throws -> User
    
    // Updates the current user's profile information.
    // Returns the updated User object.
    func updateProfile(profileData: UpdateProfileRequest) async throws -> User
    
    // Fetches the detailed profile for the current user.
    // Note: This might overlap with AuthRepository.getCurrentUser(). Decide where it fits best.
    // func getMyProfile() async throws -> User
} 