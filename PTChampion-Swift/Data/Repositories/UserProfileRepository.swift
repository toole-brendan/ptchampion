import Foundation

// Concrete implementation of the UserProfileRepositoryProtocol using APIClient.
class UserProfileRepository: UserProfileRepositoryProtocol {
    
    private let apiClient = APIClient.shared
    
    func updateUserLocation(latitude: Double, longitude: Double) async throws -> User {
        return try await apiClient.updateUserLocation(latitude: latitude, longitude: longitude)
    }
    
    func updateProfile(profileData: UpdateProfileRequest) async throws -> User {
        return try await apiClient.updateProfile(profileData: profileData)
    }
    
    // Note: getMyProfile() is currently handled by AuthRepository.getCurrentUser()
    // If more complex profile fetching logic is needed later, it could be added here.
} 