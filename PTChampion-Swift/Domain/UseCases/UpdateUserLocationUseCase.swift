import Foundation

// Use case for updating user location.
class UpdateUserLocationUseCase {
    // Depend on the repository protocol, not the concrete implementation.
    private let userProfileRepository: UserProfileRepositoryProtocol
    
    // Inject the repository dependency.
    init(userProfileRepository: UserProfileRepositoryProtocol) {
        self.userProfileRepository = userProfileRepository
    }
    
    // Executes the update location operation.
    // Takes latitude and longitude, returns the updated User object on success.
    func execute(latitude: Double, longitude: Double) async throws -> User {
        // Input validation could be added here if needed.
        
        // Call the repository method to perform the location update.
        return try await userProfileRepository.updateUserLocation(latitude: latitude, longitude: longitude)
    }
} 