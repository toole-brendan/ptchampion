import Foundation

// Protocol for authentication operations
protocol AuthRepositoryProtocol {
    func login(username: String, password: String) async throws -> User
    func register(username: String, password: String) async throws -> User
    func validateToken() async throws -> Bool
    func logout() async throws
    func getCurrentUser() async throws -> User
    // Add functions for logout, token refresh etc. if needed
}

// Concrete implementation using APIClient
class AuthRepository: AuthRepositoryProtocol {
    private let apiClient = APIClient.shared
    private let tokenManager = AuthTokenManager.shared

    func login(username: String, password: String) async throws -> User {
        return try await apiClient.login(username: username, password: password)
    }

    func register(username: String, password: String) async throws -> User {
        return try await apiClient.register(username: username, password: password)
    }

    func validateToken() async throws -> Bool {
        return try await apiClient.validateToken()
    }

    func logout() async throws {
        try await apiClient.logout()
    }

    func getCurrentUser() async throws -> User {
        return try await apiClient.getCurrentUser()
    }

    var isLoggedIn: Bool {
        return tokenManager.getToken() != nil
    }
} 