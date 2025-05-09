import Foundation
import Combine

protocol UserServiceProtocol {
    func fetchUserProfile(userID: String) -> AnyPublisher<UserProfileData, Error>
    // TODO: Potentially add other user-related methods here, e.g.:
    // func updateUserProfile(_ profile: UserProfileData) -> AnyPublisher<Void, Error>
    // func fetchUserFriends(userID: String) -> AnyPublisher<[UserSummary], Error>
}

// Example Error for the service
enum UserServiceError: Error, LocalizedError {
    case networkError(Error)
    case parsingError(Error)
    case userNotFound
    case unknown

    var errorDescription: String? {
        switch self {
        case .networkError(let underlyingError):
            return "Network error: \(underlyingError.localizedDescription)"
        case .parsingError:
            return "Failed to parse user profile data."
        case .userNotFound:
            return "User profile not found."
        case .unknown:
            return "An unknown error occurred."
        }
    }
} 