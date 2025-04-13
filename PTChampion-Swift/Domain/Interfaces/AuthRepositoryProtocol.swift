import Foundation

// Defines the contract for authentication-related data operations.
protocol AuthRepositoryProtocol {
    // Attempts to log in a user with the given credentials.
    // Returns the User object on success.
    func login(username: String, password: String) async throws -> User

    // Attempts to register a new user with the given credentials.
    // Returns the User object on success.
    func register(username: String, password: String) async throws -> User

    // Validates the currently stored authentication token.
    // Returns true if the token is valid, false otherwise.
    func validateToken() async throws -> Bool

    // Logs the current user out, clearing any stored credentials.
    func logout() async throws

    // Retrieves the currently authenticated user's profile.
    // Throws an error if no user is authenticated or fetch fails.
    func getCurrentUser() async throws -> User
    
    // Checks if a user is currently logged in (e.g., has a valid token).
    // Note: This might just check for token existence locally or perform a quick validation.
    // Consider if `validateToken` or `getCurrentUser` is preferred for definite status.
    var isLoggedIn: Bool { get }
} 