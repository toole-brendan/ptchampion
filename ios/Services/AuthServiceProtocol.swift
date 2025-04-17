import Foundation
import Combine

// Protocol defining the interface for authentication network calls
protocol AuthServiceProtocol {
    func login(credentials: LoginRequest) async throws -> AuthResponse
    func register(userInfo: RegistrationRequest) async throws -> Void // Or AuthResponse if register logs in
    // Add other auth-related methods if needed (e.g., forgotPassword, refreshToken)

    // Potentially add a method to fetch the current user profile
    // func getCurrentUserProfile() async throws -> User
} 